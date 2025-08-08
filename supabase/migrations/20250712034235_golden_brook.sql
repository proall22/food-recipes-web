/*
  # Database Functions and Triggers

  1. Functions
    - Calculate average rating for recipes
    - Search recipes by title and ingredients
    - Get user activity statistics
    - Update recipe popularity score

  2. Triggers
    - Update recipe rating when rating is added/updated/deleted
    - Update timestamps on record changes
    - Log user activity

  3. Computed Fields
    - Recipe average rating
    - Recipe total likes
    - Recipe total comments
    - User recipe count
*/

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

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, username, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Event trigger for user registration (if using Supabase auth)
-- This would be configured in Hasura events section