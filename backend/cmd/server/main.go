package main

import (
	"log"
	"os"
	"time"
	"context"
	"recipe-backend/internal/config"
	"recipe-backend/internal/handlers"
	"recipe-backend/internal/middleware"
	"recipe-backend/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Initialize configuration
	cfg := config.New()
	
	log.Printf("Configuration loaded:")
	log.Printf("- Hasura Endpoint: %s", cfg.HasuraEndpoint)
	log.Printf("- Hasura Admin Secret: %s", cfg.HasuraAdminSecret)
	log.Printf("- Database URL: %s", cfg.DatabaseURL)
	log.Printf("- JWT Secret length: %d", len(cfg.JWTSecret))

	// Initialize services
	log.Println("Initializing services...")
	authService := services.NewAuthService(cfg)
	fileService := services.NewFileService(cfg)
	chapaService := services.NewChapaService(cfg)
	hasuraService := services.NewHasuraService(cfg)
	
	// Test Hasura connection
	log.Println("Testing Hasura connection...")
	testCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	testQuery := `query { __schema { queryType { name } } }`
	_, err := hasuraService.ExecuteQuery(testCtx, testQuery, nil)
	if err != nil {
		log.Printf("WARNING: Hasura connection test failed: %v", err)
	} else {
		log.Println("Hasura connection test successful")
	}

	// Initialize handlers
	log.Println("Initializing handlers...")
	authHandler := handlers.NewAuthHandler(authService, hasuraService)
	fileHandler := handlers.NewFileHandler(fileService)
	paymentHandler := handlers.NewPaymentHandler(chapaService, hasuraService)

	// Setup Gin router
	log.Println("Setting up router...")
	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())
	r.Use(middleware.Logger())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		log.Println("Health check requested")
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API routes
	log.Println("Setting up API routes...")
	api := r.Group("/api/v1")
	{
		// Auth routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
		}

		// File upload routes
		files := api.Group("/files")
		files.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			files.POST("/upload", fileHandler.UploadFile)
			files.DELETE("/:fileId", fileHandler.DeleteFile)
		}

		// Payment routes
		payments := api.Group("/payments")
		payments.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			payments.POST("/initialize", paymentHandler.InitializePayment)
			payments.POST("/verify", paymentHandler.VerifyPayment)
			payments.GET("/status/:transactionId", paymentHandler.GetPaymentStatus)
		}
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8000"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📊 Health check: http://localhost:%s/health", port)
	log.Printf("🔐 Auth endpoints: http://localhost:%s/api/v1/auth/*", port)
	
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}