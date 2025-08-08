-- Drop triggers
DROP TRIGGER IF EXISTS update_purchases_updated_at ON purchases;
DROP TRIGGER IF EXISTS update_ratings_updated_at ON ratings;
DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
DROP TRIGGER IF EXISTS update_recipes_updated_at ON recipes;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS get_popular_recipes(integer);
DROP FUNCTION IF EXISTS search_recipes(text);
DROP FUNCTION IF EXISTS count_user_recipes(users);
DROP FUNCTION IF EXISTS count_recipe_comments(recipes);
DROP FUNCTION IF EXISTS count_recipe_likes(recipes);
DROP FUNCTION IF EXISTS calculate_recipe_rating(recipes);