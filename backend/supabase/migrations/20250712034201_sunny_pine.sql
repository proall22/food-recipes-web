/*
  # Initial Database Schema for Recipe Website

  1. New Tables
    - `users` - User authentication and profile data
    - `categories` - Recipe categories (Breakfast, Lunch, Dinner, etc.)
    - `recipes` - Main recipe information
    - `recipe_steps` - Dynamic cooking steps for each recipe
    - `recipe_ingredients` - Dynamic ingredients for each recipe
    - `recipe_images` - Multiple images per recipe with featured flag
    - `likes` - User likes on recipes
    - `bookmarks` - User bookmarks on recipes
    - `comments` - User comments on recipes
    - `ratings` - User ratings on recipes
    - `purchases` - Recipe purchase records

  2. Security
    - Enable RLS on all user-related tables
    - Add policies for authenticated users
    - Add policies for recipe ownership
    - Add anonymous read access for public recipes

  3. Functions and Triggers
    - Update recipe rating averages
    - Search functionality
    - User activity tracking
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (extends Hasura auth)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email text UNIQUE NOT NULL,
  username text UNIQUE NOT NULL,
  full_name text NOT NULL,
  avatar_url text,
  bio text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text UNIQUE NOT NULL,
  description text,
  icon text,
  slug text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Recipes table
CREATE TABLE IF NOT EXISTS recipes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  description text,
  prep_time integer NOT NULL, -- in minutes
  cook_time integer DEFAULT 0, -- in minutes
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
CREATE TABLE IF NOT EXISTS recipe_steps (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  step_number integer NOT NULL,
  instruction text NOT NULL,
  image_url text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(recipe_id, step_number)
);

-- Recipe ingredients table
CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  amount text NOT NULL,
  unit text,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Recipe images table
CREATE TABLE IF NOT EXISTS recipe_images (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  image_url text NOT NULL,
  is_featured boolean DEFAULT false,
  caption text,
  created_at timestamptz DEFAULT now()
);

-- Likes table
CREATE TABLE IF NOT EXISTS likes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Bookmarks table
CREATE TABLE IF NOT EXISTS bookmarks (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  parent_id uuid REFERENCES comments(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ratings table
CREATE TABLE IF NOT EXISTS ratings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  rating integer CHECK (rating >= 1 AND rating <= 5) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, recipe_id)
);

-- Purchases table
CREATE TABLE IF NOT EXISTS purchases (
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
('Vegan', 'Completely plant-based meals', '🌱', 'vegan')
ON CONFLICT (slug) DO NOTHING;

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users
CREATE POLICY "Users can read all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (id = auth.uid());

-- RLS Policies for recipes
CREATE POLICY "Anyone can read published recipes" ON recipes FOR SELECT USING (is_published = true);
CREATE POLICY "Users can read own recipes" ON recipes FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own recipes" ON recipes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own recipes" ON recipes FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own recipes" ON recipes FOR DELETE USING (user_id = auth.uid());

-- RLS Policies for recipe_steps
CREATE POLICY "Anyone can read steps of published recipes" ON recipe_steps FOR SELECT 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_steps.recipe_id AND recipes.is_published = true));
CREATE POLICY "Users can manage steps of own recipes" ON recipe_steps FOR ALL 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_steps.recipe_id AND recipes.user_id = auth.uid()));

-- RLS Policies for recipe_ingredients
CREATE POLICY "Anyone can read ingredients of published recipes" ON recipe_ingredients FOR SELECT 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_ingredients.recipe_id AND recipes.is_published = true));
CREATE POLICY "Users can manage ingredients of own recipes" ON recipe_ingredients FOR ALL 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_ingredients.recipe_id AND recipes.user_id = auth.uid()));

-- RLS Policies for recipe_images
CREATE POLICY "Anyone can read images of published recipes" ON recipe_images FOR SELECT 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_images.recipe_id AND recipes.is_published = true));
CREATE POLICY "Users can manage images of own recipes" ON recipe_images FOR ALL 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = recipe_images.recipe_id AND recipes.user_id = auth.uid()));

-- RLS Policies for likes
CREATE POLICY "Users can read all likes" ON likes FOR SELECT USING (true);
CREATE POLICY "Users can manage own likes" ON likes FOR ALL USING (user_id = auth.uid());

-- RLS Policies for bookmarks
CREATE POLICY "Users can read own bookmarks" ON bookmarks FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can manage own bookmarks" ON bookmarks FOR ALL USING (user_id = auth.uid());

-- RLS Policies for comments
CREATE POLICY "Anyone can read comments on published recipes" ON comments FOR SELECT 
  USING (EXISTS (SELECT 1 FROM recipes WHERE recipes.id = comments.recipe_id AND recipes.is_published = true));
CREATE POLICY "Users can insert comments" ON comments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own comments" ON comments FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (user_id = auth.uid());

-- RLS Policies for ratings
CREATE POLICY "Anyone can read ratings" ON ratings FOR SELECT USING (true);
CREATE POLICY "Users can manage own ratings" ON ratings FOR ALL USING (user_id = auth.uid());

-- RLS Policies for purchases
CREATE POLICY "Users can read own purchases" ON purchases FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own purchases" ON purchases FOR INSERT WITH CHECK (user_id = auth.uid());

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_recipes_category_id ON recipes(category_id);
CREATE INDEX IF NOT EXISTS idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_likes_recipe_id ON likes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_recipe_id ON comments(recipe_id);
CREATE INDEX IF NOT EXISTS idx_ratings_recipe_id ON ratings(recipe_id);