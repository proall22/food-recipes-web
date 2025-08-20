-- Add analytics and search tables

-- Recipe views table for tracking
CREATE TABLE IF NOT EXISTS recipe_views (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id uuid REFERENCES recipes(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Search logs table for analytics
CREATE TABLE IF NOT EXISTS search_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  search_term text NOT NULL,
  results_count integer DEFAULT 0,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  count integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(search_term)
);

-- Email notifications queue
CREATE TABLE IF NOT EXISTS email_notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_email text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  template_type text NOT NULL,
  template_data jsonb,
  status text CHECK (status IN ('pending', 'sent', 'failed')) DEFAULT 'pending',
  sent_at timestamptz,
  error_message text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- User activity logs
CREATE TABLE IF NOT EXISTS user_activities (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  activity_type text NOT NULL,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for analytics
CREATE INDEX IF NOT EXISTS idx_recipe_views_recipe_id ON recipe_views(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_views_user_id ON recipe_views(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_views_created_at ON recipe_views(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_search_logs_search_term ON search_logs(search_term);
CREATE INDEX IF NOT EXISTS idx_search_logs_created_at ON search_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_created_at ON user_activities(created_at DESC);

-- Function to log user activity
CREATE OR REPLACE FUNCTION log_user_activity(
  p_user_id uuid,
  p_activity_type text,
  p_entity_type text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  INSERT INTO user_activities (user_id, activity_type, entity_type, entity_id, metadata)
  VALUES (p_user_id, p_activity_type, p_entity_type, p_entity_id, p_metadata);
END;
$$ LANGUAGE plpgsql;

-- Function to get recipe analytics
CREATE OR REPLACE FUNCTION get_recipe_analytics(p_recipe_id uuid)
RETURNS TABLE(
  total_views bigint,
  unique_viewers bigint,
  total_likes bigint,
  total_comments bigint,
  average_rating numeric,
  total_ratings bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE((SELECT COUNT(*) FROM recipe_views WHERE recipe_id = p_recipe_id), 0) as total_views,
    COALESCE((SELECT COUNT(DISTINCT user_id) FROM recipe_views WHERE recipe_id = p_recipe_id AND user_id IS NOT NULL), 0) as unique_viewers,
    COALESCE((SELECT COUNT(*) FROM likes WHERE recipe_id = p_recipe_id), 0) as total_likes,
    COALESCE((SELECT COUNT(*) FROM comments WHERE recipe_id = p_recipe_id), 0) as total_comments,
    COALESCE((SELECT AVG(rating) FROM ratings WHERE recipe_id = p_recipe_id), 0) as average_rating,
    COALESCE((SELECT COUNT(*) FROM ratings WHERE recipe_id = p_recipe_id), 0) as total_ratings;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get user analytics
CREATE OR REPLACE FUNCTION get_user_analytics(p_user_id uuid)
RETURNS TABLE(
  total_recipes bigint,
  total_views bigint,
  total_likes_received bigint,
  total_comments_received bigint,
  average_rating numeric,
  total_followers bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE((SELECT COUNT(*) FROM recipes WHERE user_id = p_user_id AND is_published = true), 0) as total_recipes,
    COALESCE((SELECT COUNT(*) FROM recipe_views rv JOIN recipes r ON rv.recipe_id = r.id WHERE r.user_id = p_user_id), 0) as total_views,
    COALESCE((SELECT COUNT(*) FROM likes l JOIN recipes r ON l.recipe_id = r.id WHERE r.user_id = p_user_id), 0) as total_likes_received,
    COALESCE((SELECT COUNT(*) FROM comments c JOIN recipes r ON c.recipe_id = r.id WHERE r.user_id = p_user_id), 0) as total_comments_received,
    COALESCE((SELECT AVG(rt.rating) FROM ratings rt JOIN recipes r ON rt.recipe_id = r.id WHERE r.user_id = p_user_id), 0) as average_rating,
    0 as total_followers; -- Placeholder for followers feature
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to log recipe views
CREATE OR REPLACE FUNCTION log_recipe_view()
RETURNS TRIGGER AS $$
BEGIN
  -- This would be called from the application when a recipe is viewed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update search logs count
CREATE OR REPLACE FUNCTION update_search_log_count()
RETURNS TRIGGER AS $$
BEGIN
  NEW.count = NEW.count + 1;
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_search_logs_count
  BEFORE UPDATE ON search_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_search_log_count();

-- Trigger to update email notifications timestamp
CREATE TRIGGER update_email_notifications_updated_at
  BEFORE UPDATE ON email_notifications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();