#!/bin/bash

set -e  # Exit on any error

echo "Setting up Hasura metadata and tracking tables..."

# Wait for Hasura to be ready
echo "Waiting for Hasura to be ready..."
until curl -f -s http://localhost:8080/healthz > /dev/null 2>&1; do
  echo "Waiting for Hasura..."
  sleep 5
done

echo "Hasura is ready! Setting up database connection..."

# Check if source already exists
echo "Checking if database source exists..."
SOURCE_CHECK=$(curl -s -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{"type": "export_metadata", "args": {}}' | jq -r '.sources // []' | jq 'length')

if [ "$SOURCE_CHECK" -eq "0" ]; then
  echo "Adding database source..."
# First, add the database source
  curl -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{
    "type": "pg_add_source",
    "args": {
      "name": "default",
      "configuration": {
        "connection_info": {
          "database_url": "postgres://postgres:postgrespassword@postgres:5432/recipes_db",
          "isolation_level": "read-committed",
          "pool_settings": {
            "connection_lifetime": 600,
            "idle_timeout": 180,
            "max_connections": 50,
            "retries": 1
          },
          "use_prepared_statements": true
        }
      }
    }
  }'
else
  echo "Database source already exists, skipping..."
fi

echo "Database source added. Waiting for connection to stabilize..."
sleep 10

# Check if tables exist, if not create them
echo "Checking and creating database schema..."
docker exec -i $(docker-compose ps -q postgres) psql -U postgres -d recipes_db << 'EOF'
-- Check if users table exists, if not create the schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
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
        RETURNS numeric AS $func$
          SELECT COALESCE(AVG(rating), 0)
          FROM ratings
          WHERE recipe_id = recipe_row.id;
        $func$ LANGUAGE sql STABLE;

        -- Function to count total likes for a recipe
        CREATE OR REPLACE FUNCTION count_recipe_likes(recipe_row recipes)
        RETURNS bigint AS $func$
          SELECT COUNT(*)
          FROM likes
          WHERE recipe_id = recipe_row.id;
        $func$ LANGUAGE sql STABLE;

        -- Function to count total comments for a recipe
        CREATE OR REPLACE FUNCTION count_recipe_comments(recipe_row recipes)
        RETURNS bigint AS $func$
          SELECT COUNT(*)
          FROM comments
          WHERE recipe_id = recipe_row.id;
        $func$ LANGUAGE sql STABLE;

        -- Function to count user's total recipes
        CREATE OR REPLACE FUNCTION count_user_recipes(user_row users)
        RETURNS bigint AS $func$
          SELECT COUNT(*)
          FROM recipes
          WHERE user_id = user_row.id AND is_published = true;
        $func$ LANGUAGE sql STABLE;

        -- Function to search recipes
        CREATE OR REPLACE FUNCTION search_recipes(search_term text)
        RETURNS SETOF recipes AS $func$
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
        $func$ LANGUAGE sql STABLE;

        -- Function to get popular recipes
        CREATE OR REPLACE FUNCTION get_popular_recipes(limit_count integer DEFAULT 10)
        RETURNS SETOF recipes AS $func$
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
        $func$ LANGUAGE sql STABLE;

        -- Function to update updated_at timestamp
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $func$
        BEGIN
          NEW.updated_at = now();
          RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql;

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
        
        RAISE NOTICE 'Sample users created';

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

        INSERT INTO recipes (title, description, prep_time, cook_time, servings, difficulty, category_id, user_id, featured_image_url, is_published) 
        SELECT 
          'Chocolate Chip Cookies',
          'Classic homemade chocolate chip cookies',
          20,
          12,
          24,
          'Easy',
          c.id,
          u.id,
          'https://images.pexels.com/photos/230325/pexels-photo-230325.jpeg?auto=compress&cs=tinysrgb&w=600',
          true
        FROM categories c, users u 
        WHERE c.slug = 'desserts' AND u.username = 'john_chef'
        LIMIT 1;

        INSERT INTO recipes (title, description, prep_time, cook_time, servings, difficulty, category_id, user_id, featured_image_url, is_published) 
        SELECT 
          'Caesar Salad',
          'Fresh and crispy Caesar salad with homemade dressing',
          15,
          0,
          2,
          'Easy',
          c.id,
          u.id,
          'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg?auto=compress&cs=tinysrgb&w=600',
          true
        FROM categories c, users u 
        WHERE c.slug = 'lunch' AND u.username = 'jane_cook'
        LIMIT 1;

        -- Add ingredients for pancakes
        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'All-purpose flour', '2', 'cups', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Sugar', '2', 'tablespoons', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Baking powder', '2', 'teaspoons', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Salt', '1', 'teaspoon', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Milk', '1 3/4', 'cups', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Egg', '1', 'large', ''
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_ingredients (recipe_id, name, amount, unit, notes)
        SELECT r.id, 'Butter', '3', 'tablespoons', 'melted'
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        -- Add steps for pancakes
        INSERT INTO recipe_steps (recipe_id, step_number, instruction)
        SELECT r.id, 1, 'In a large bowl, whisk together flour, sugar, baking powder, and salt.'
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_steps (recipe_id, step_number, instruction)
        SELECT r.id, 2, 'In another bowl, whisk together milk, egg, and melted butter.'
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_steps (recipe_id, step_number, instruction)
        SELECT r.id, 3, 'Pour the wet ingredients into the dry ingredients and stir until just combined. Do not overmix.'
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_steps (recipe_id, step_number, instruction)
        SELECT r.id, 4, 'Heat a griddle or large skillet over medium heat. Pour 1/4 cup of batter for each pancake.'
        FROM recipes r WHERE r.title = 'Classic Pancakes';

        INSERT INTO recipe_steps (recipe_id, step_number, instruction)
        SELECT r.id, 5, 'Cook until bubbles form on surface and edges look set, about 2-3 minutes. Flip and cook until golden brown.'
        FROM recipes r WHERE r.title = 'Classic Pancakes';
        
        RAISE NOTICE 'Sample recipe data created';

        RAISE NOTICE 'Database schema created successfully!';
    ELSE
        RAISE NOTICE 'Database schema already exists.';
    END IF;
END
$$;
EOF

if [ $? -eq 0 ]; then
  echo "✅ Database schema setup complete!"
else
  echo "❌ Database schema setup failed!"
  exit 1
fi

echo "Database schema setup complete. Now tracking tables in Hasura..."

# Function to track table with error handling
track_table() {
  local table_name=$1
  echo "Tracking table: $table_name"
  
  RESPONSE=$(curl -s -X POST \
    http://localhost:8080/v1/metadata \
    -H 'Content-Type: application/json' \
    -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
    -d "{
      \"type\": \"pg_track_table\",
      \"args\": {
        \"source\": \"default\",
        \"table\": {
          \"schema\": \"public\",
          \"name\": \"$table_name\"
        }
      }
    }")
    
  if echo "$RESPONSE" | grep -q "error"; then
    echo "⚠️  Warning: Failed to track table $table_name or already tracked"
    echo "Response: $RESPONSE"
  else
    echo "✅ Successfully tracked table: $table_name"
  fi
}

# Track all tables
echo "Tracking all tables..."
track_table "users"
track_table "categories"
track_table "recipes"
track_table "recipe_steps"
track_table "recipe_ingredients"
track_table "recipe_images"
track_table "likes"
track_table "bookmarks"
track_table "comments"
track_table "ratings"
track_table "purchases"

echo "Tables tracked. Now tracking functions..."

# Track functions
curl -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{
    "type": "bulk",
    "args": [
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "calculate_recipe_rating"
          }
        }
      },
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "count_recipe_likes"
          }
        }
      },
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "count_recipe_comments"
          }
        }
      },
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "count_user_recipes"
          }
        }
      },
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "search_recipes"
          }
        }
      },
      {
        "type": "pg_track_function",
        "args": {
          "source": "default",
          "function": {
            "schema": "public",
            "name": "get_popular_recipes"
          }
        }
      }
    ]
  }'

echo "Functions tracked. Now creating relationships..."

# Create relationships
curl -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{
    "type": "bulk",
    "args": [
      {
        "type": "pg_create_object_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "user",
          "using": {
            "foreign_key_constraint_on": "user_id"
          }
        }
      },
      {
        "type": "pg_create_object_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "category",
          "using": {
            "foreign_key_constraint_on": "category_id"
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "ingredients",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "recipe_ingredients"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "steps",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "recipe_steps"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "images",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "recipe_images"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "likes",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "likes"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "comments",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "comments"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "ratings",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "ratings"
              },
              "column": "recipe_id"
            }
          }
        }
      },
      {
        "type": "pg_create_array_relationship",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "categories"
          },
          "name": "recipes",
          "using": {
            "foreign_key_constraint_on": {
              "table": {
                "schema": "public",
                "name": "recipes"
              },
              "column": "category_id"
            }
          }
        }
      }
    ]
  }'

echo "Relationships created. Now adding computed fields..."

# Add computed fields
curl -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{
    "type": "bulk",
    "args": [
      {
        "type": "pg_add_computed_field",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "average_rating",
          "definition": {
            "function": {
              "schema": "public",
              "name": "calculate_recipe_rating"
            }
          }
        }
      },
      {
        "type": "pg_add_computed_field",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "total_likes",
          "definition": {
            "function": {
              "schema": "public",
              "name": "count_recipe_likes"
            }
          }
        }
      },
      {
        "type": "pg_add_computed_field",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "name": "total_comments",
          "definition": {
            "function": {
              "schema": "public",
              "name": "count_recipe_comments"
            }
          }
        }
      },
      {
        "type": "pg_add_computed_field",
        "args": {
          "source": "default",
          "table": {
            "schema": "public",
            "name": "users"
          },
          "name": "recipe_count",
          "definition": {
            "function": {
              "schema": "public",
              "name": "count_user_recipes"
            }
          }
        }
      }
    ]
  }'

echo "Computed fields added. Adding aggregate relationships..."

# Add aggregate relationships for categories
curl -X POST \
  http://localhost:8080/v1/metadata \
  -H 'Content-Type: application/json' \
  -H 'X-Hasura-Admin-Secret: myadminsecretkey' \
  -d '{
    "type": "pg_create_array_relationship",
    "args": {
      "source": "default",
      "table": {
        "schema": "public",
        "name": "categories"
      },
      "name": "recipes_aggregate",
      "using": {
        "foreign_key_constraint_on": {
          "table": {
            "schema": "public",
            "name": "recipes"
          },
          "column": "category_id"
        }
      }
    }
  }'

echo "Hasura setup complete! All tables, relationships, and computed fields have been configured."
echo "You can now access:"
echo "- Hasura Console: http://localhost:8080"
echo "- Frontend: http://localhost:3000"
echo "- Backend API: http://localhost:8000"