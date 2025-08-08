-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email text UNIQUE NOT NULL,
  username text UNIQUE NOT NULL,
  full_name text NOT NULL,
  password_hash text NOT NULL,
  avatar_url text,
  bio text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Categories table
CREATE TABLE categories (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text UNIQUE NOT NULL,
  description text,
  icon text,
  slug text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Recipes table
CREATE TABLE recipes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  prep_time integer NOT NULL,
  cook_time integer DEFAULT 0,
  servings integer DEFAULT 1,
  difficulty text CHECK (difficulty IN ('Easy', 'Medium', 'Hard')) DEFAULT 'Easy',
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  featured_image_url text,
  is_premium boolean DEFAULT false,
  price decimal(10,2) DEFAULT 0.00,
  is_published boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Recipe steps table
CREATE TABLE recipe_steps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  step_number integer NOT NULL,
  instruction text NOT NULL,
  image_url text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(recipe_id, step_number)
);

-- Recipe ingredients table
CREATE TABLE recipe_ingredients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  amount text NOT NULL,
  unit text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Recipe images table
CREATE TABLE recipe_images (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  image_url text NOT NULL,
  is_featured boolean DEFAULT false,
  caption text,
  created_at timestamptz DEFAULT now()
);

-- Likes table
CREATE TABLE likes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Bookmarks table
CREATE TABLE bookmarks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Comments table
CREATE TABLE comments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  parent_id uuid REFERENCES comments(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ratings table
CREATE TABLE ratings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  rating integer CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Purchases table
CREATE TABLE purchases (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  amount decimal(10,2) NOT NULL,
  payment_method text DEFAULT 'chapa',
  transaction_id text UNIQUE,
  status text CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Insert default categories
INSERT INTO categories (name, description, icon, slug) VALUES
('Breakfast', 'Start your day with delicious breakfast recipes', '🍳', 'breakfast'),
('Lunch', 'Quick and satisfying lunch ideas', '🥗', 'lunch'),
('Dinner', 'Hearty dinner recipes for the whole family', '🍝', 'dinner'),
('Desserts', 'Sweet treats and desserts', '🍰', 'desserts'),
('Snacks', 'Quick bites and appetizers', '🍿', 'snacks'),
('Drinks', 'Refreshing beverages and cocktails', '🥤', 'drinks'),
('Vegetarian', 'Plant-based recipes', '🥕', 'vegetarian'),
('Vegan', 'Completely plant-based meals', '🌱', 'vegan');

-- Create indexes for better performance
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_category_id ON recipes(category_id);
CREATE INDEX idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_likes_recipe_id ON likes(recipe_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_comments_recipe_id ON comments(recipe_id);
CREATE INDEX idx_ratings_recipe_id ON ratings(recipe_id);

-- Function to calculate average rating for a recipe
CREATE OR REPLACE FUNCTION calculate_recipe_rating(recipe_row recipes)
RETURNS numeric AS $$
  SELECT COALESCE(AVG(rating), 0)
  FROM ratings
  WHERE recipe_id = recipe_row.id;
$$ LANGUAGE sql STABLE;

-- Function to count total likes for a recipe
CREATE OR REPLACE FUNCTION count_recipe_likes(recipe_row recipes)
RETURNS bigint AS $$
  SELECT COUNT(*)
  FROM likes
  WHERE recipe_id = recipe_row.id;
$$ LANGUAGE sql STABLE;

-- Function to count total comments for a recipe
CREATE OR REPLACE FUNCTION count_recipe_comments(recipe_row recipes)
RETURNS bigint AS $$
  SELECT COUNT(*)
  FROM comments
  WHERE recipe_id = recipe_row.id;
$$ LANGUAGE sql STABLE;

-- Function to count user's total recipes
CREATE OR REPLACE FUNCTION count_user_recipes(user_row users)
RETURNS bigint AS $$
  SELECT COUNT(*)
  FROM recipes
  WHERE user_id = user_row.id AND is_published = true;
$$ LANGUAGE sql STABLE;

-- Function to search recipes
CREATE OR REPLACE FUNCTION search_recipes(search_term text)
RETURNS SETOF recipes AS $$
  SELECT r.*
  FROM recipes r
  LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
  WHERE r.is_published = true
    AND (
      r.title ILIKE '%' || search_term || '%'
      OR r.description ILIKE '%' || search_term || '%'
      OR ri.name ILIKE '%' || search_term || '%'
    )
  GROUP BY r.id
  ORDER BY r.created_at DESC;
$$ LANGUAGE sql STABLE;

-- Function to get popular recipes
CREATE OR REPLACE FUNCTION get_popular_recipes(limit_count integer DEFAULT 10)
RETURNS SETOF recipes AS $$
  SELECT r.*
  FROM recipes r
  LEFT JOIN likes l ON r.id = l.recipe_id
  LEFT JOIN ratings rt ON r.id = rt.recipe_id
  WHERE r.is_published = true
  GROUP BY r.id
  ORDER BY 
    COUNT(l.id) DESC,
    AVG(rt.rating) DESC NULLS LAST,
    r.created_at DESC
  LIMIT limit_count;
$$ LANGUAGE sql STABLE;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updating timestamps
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipes_updated_at
  BEFORE UPDATE ON recipes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ratings_updated_at
  BEFORE UPDATE ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing
INSERT INTO users (email, username, full_name, password_hash) VALUES
('john@example.com', 'john_chef', 'John Smith', '$2a$14$example_hash_here'),
('jane@example.com', 'jane_cook', 'Jane Doe', '$2a$14$example_hash_here');

-- Insert sample recipes
INSERT INTO recipes (title, description, prep_time, cook_time, servings, difficulty, category_id, user_id, featured_image_url, is_published) 
SELECT 
  'Classic Pancakes',
  'Fluffy and delicious pancakes perfect for breakfast',
  10,
  15,
  4,
  'Easy',
  c.id,
  u.id,
  'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg?auto=compress&cs=tinysrgb&w=600',
  true
FROM categories c, users u 
WHERE c.slug = 'breakfast' AND u.username = 'john_chef'
LIMIT 1;

INSERT INTO recipes (title, description, prep_time, cook_time, servings, difficulty, category_id, user_id, featured_image_url, is_published) 
SELECT 
  'Spaghetti Carbonara',
  'Creamy Italian pasta dish with eggs and cheese',
  15,
  20,
  2,
  'Medium',
  c.id,
  u.id,
  'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600',
  true
FROM categories c, users u 
WHERE c.slug = 'dinner' AND u.username = 'jane_cook'
LIMIT 1;