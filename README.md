# Recipe Website - Full Stack Implementation

A comprehensive food recipe website built with Nuxt 3, Hasura GraphQL, PostgreSQL, and Golang backend.

## Features

### Frontend (Nuxt 3 + Vue 3)

- 🎨 Beautiful, responsive UI with Tailwind CSS
- 🔍 Advanced recipe search and filtering
- 📱 Mobile-first responsive design
- 🎭 Smooth animations and micro-interactions
- 🔐 JWT-based authentication
- 📸 Multiple image upload with featured image selection
- ⭐ Recipe rating and review system
- 💖 Like and bookmark functionality
- 💬 Comment system with nested replies
- 💳 Payment integration with Chapa

### Backend (Golang + Hasura)

- 🚀 High-performance Golang API server
- 📊 Hasura GraphQL engine with real-time subscriptions
- 🔒 Row-level security (RLS) with PostgreSQL
- 📁 File upload to AWS S3
- 💰 Chapa payment gateway integration
- 🔑 JWT authentication with refresh tokens
- 📧 Email notifications (planned)
- 📈 Analytics and user activity tracking

### Database (PostgreSQL)

- 🗃️ Comprehensive schema with proper relationships
- 🔍 Full-text search capabilities
- 📊 Computed fields for aggregated data
- ⚡ Optimized indexes for performance
- 🔄 Database triggers for real-time updates
- 🛡️ Row-level security policies

## Tech Stack

### Frontend

- **Nuxt 3** - Vue.js framework
- **Vue 3** - Progressive JavaScript framework
- **Tailwind CSS** - Utility-first CSS framework
- **Vue Apollo** - GraphQL client
- **Vee-validate** - Form validation
- **Heroicons** - Beautiful SVG icons

### Backend

- **Golang** - Backend API server
- **Hasura** - GraphQL engine
- **PostgreSQL** - Primary database
- **Docker** - Containerization
- **AWS S3** - File storage
- **Chapa** - Payment processing

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ and npm
- Go 1.21+

### 1. Start the Backend Services

```bash
# Start PostgreSQL and Hasura
docker-compose up -d postgres hasura

# Wait for services to be ready (about 30 seconds), then setup Hasura
./setup-hasura.sh

# Start Golang backend
docker-compose up -d golang-backend
```

### 2. Setup Hasura

The database schema and Hasura metadata will be automatically set up when you run the setup script above.

You can verify everything is working by:

1. Opening Hasura Console: http://localhost:8080
2. Check that all tables are visible in the Data tab
3. Try running a test query in the GraphiQL tab

### 3. Start the Frontend

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

### 4. Access the Application

- **Frontend**: http://localhost:3000
- **Hasura Console**: http://localhost:8080
- **Golang API**: http://localhost:8000

## Troubleshooting

### If you don't see tables in Hasura:

1. Stop all services: `docker-compose down`
2. Remove volumes: `docker-compose down -v`
3. Start services again: `docker-compose up -d postgres hasura`
4. Wait 30 seconds, then run: `./setup-hasura.sh`
5. Start backend: `docker-compose up -d golang-backend`

### If the frontend shows 503 errors:

1. Make sure all Docker services are running: `docker-compose ps`
2. Check that Hasura is accessible: `curl http://localhost:8080/healthz`
3. Verify the backend is running: `curl http://localhost:8000/health`

### Local PostgreSQL conflicts:

If you have a local PostgreSQL running on port 5432, either:

1. Stop your local PostgreSQL: `sudo service postgresql stop`
2. Or change the port in docker-compose.yml to something else like `5433:5432`

## Environment Variables

Create a `.env` file in the root directory:

```env
# Hasura
HASURA_ENDPOINT=http://localhost:8080/v1/graphql
HASURA_ADMIN_SECRET=myadminsecretkey

# JWT
JWT_SECRET=your-256-bit-secret-key-here-make-it-long-enough

# Database
DATABASE_URL=postgres://postgres:postgrespassword@localhost:5432/recipes_db

# AWS S3
AWS_REGION=us-east-1
AWS_ACCESS_KEY=your-aws-access-key
AWS_SECRET_KEY=your-aws-secret-key
S3_BUCKET=recipe-images

# Chapa Payment
CHAPA_SECRET_KEY=your-chapa-secret-key
```

## Database Schema

### Core Tables

- `users` - User profiles and authentication
- `categories` - Recipe categories
- `recipes` - Main recipe data
- `recipe_steps` - Cooking instructions
- `recipe_ingredients` - Recipe ingredients
- `recipe_images` - Multiple images per recipe

### Social Features

- `likes` - Recipe likes
- `bookmarks` - User bookmarks
- `comments` - Recipe comments with threading
- `ratings` - Recipe ratings (1-5 stars)

### Commerce

- `purchases` - Recipe purchase records

## API Endpoints

### Authentication

- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh JWT token

### File Upload

- `POST /api/v1/files/upload` - Upload image files
- `DELETE /api/v1/files/:fileId` - Delete uploaded files

### Payments

- `POST /api/v1/payments/initialize` - Initialize payment
- `POST /api/v1/payments/verify` - Verify payment
- `GET /api/v1/payments/status/:transactionId` - Get payment status

## GraphQL Queries

### Get Recipes

```graphql
query GetRecipes($limit: Int!, $offset: Int!) {
	recipes(limit: $limit, offset: $offset, order_by: { created_at: desc }) {
		id
		title
		description
		prep_time
		cook_time
		difficulty
		featured_image_url
		average_rating
		total_likes
		user {
			username
			full_name
		}
		category {
			name
			slug
		}
	}
}
```

### Create Recipe

```graphql
mutation CreateRecipe($recipe: recipes_insert_input!) {
	insert_recipes_one(object: $recipe) {
		id
		title
		created_at
	}
}
```

## Features Implementation

### 1. User Authentication

- JWT-based authentication with Hasura
- Secure password hashing with bcrypt
- Refresh token mechanism
- Role-based access control

### 2. Recipe Management

- Create, read, update, delete recipes
- Multiple image upload with featured image
- Dynamic ingredients and steps
- Category assignment
- Difficulty levels and timing

### 3. Social Features

- Like/unlike recipes
- Bookmark recipes
- Comment system with nested replies
- 5-star rating system
- User profiles and recipe collections

### 4. Search & Discovery

- Full-text search across titles and ingredients
- Filter by category, prep time, difficulty
- Sort by popularity, rating, date
- Popular recipes algorithm

### 5. Premium Features

- Recipe monetization
- Chapa payment integration
- Purchase tracking
- Premium recipe access control

### 6. File Management

- AWS S3 integration
- Image optimization
- Secure file upload
- File deletion and cleanup

## Development

### Adding New Features

1. **Database Changes**: Add migrations in `hasura/migrations/`
2. **GraphQL Schema**: Update Hasura metadata
3. **Backend API**: Add handlers in `backend/internal/handlers/`
4. **Frontend**: Create components and pages in appropriate directories

### Testing

```bash
# Backend tests
cd backend && go test ./...

# Frontend tests
npm run test
```

### Deployment

```bash
# Build for production
npm run build

# Build Docker images
docker-compose build

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
