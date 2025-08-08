package handlers

import (
	"context"
	"log"
	"net/http"
	"strings"

	"recipe-backend/internal/models"
	"recipe-backend/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthHandler struct {
	authService   *services.AuthService
	hasuraService *services.HasuraService
}

func NewAuthHandler(authService *services.AuthService, hasuraService *services.HasuraService) *AuthHandler {
	return &AuthHandler{
		authService:   authService,
		hasuraService: hasuraService,
	}
}

func (h *AuthHandler) Register(c *gin.Context) {
	log.Printf("Registration request received")
	
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("Request binding failed: %v", err)
		// Provide user-friendly validation messages
		errorMsg := "Invalid input data"
		if strings.Contains(err.Error(), "password") {
			errorMsg = "Password must be at least 6 characters long"
		} else if strings.Contains(err.Error(), "email") {
			errorMsg = "Please provide a valid email address"
		} else if strings.Contains(err.Error(), "username") {
			errorMsg = "Username must be between 3 and 50 characters"
		} else if strings.Contains(err.Error(), "full_name") {
			errorMsg = "Full name must be between 2 and 100 characters"
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": errorMsg})
		return
	}

	// Additional validation
	if len(req.Password) < 6 {
		log.Printf("Password too short: %d characters", len(req.Password))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Password must be at least 6 characters long"})
		return
	}

	if len(req.Username) < 3 {
		log.Printf("Username too short: %d characters", len(req.Username))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username must be at least 3 characters long"})
		return
	}

	if len(req.FullName) < 2 {
		log.Printf("Full name too short: %d characters", len(req.FullName))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Full name must be at least 2 characters long"})
		return
	}
	
	log.Printf("Validation passed for user: %s", req.Email)

	// Check if user already exists
	ctx := context.Background()
	log.Printf("Checking if user exists: %s", req.Email)
	existingUser, err := h.hasuraService.GetUserByEmail(ctx, req.Email)
	if err != nil {
		log.Printf("Error checking existing user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check existing user"})
		return
	}

	if existingUser != nil {
		log.Printf("User already exists: %s", req.Email)
		c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
		return
	}

	// Check if username already exists
	log.Printf("Checking if username exists: %s", req.Username)
	existingUsername, err := h.hasuraService.GetUserByUsername(ctx, req.Username)
	if err != nil {
		log.Printf("Error checking existing username: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check existing username"})
		return
	}

	if existingUsername != nil {
		log.Printf("Username already exists: %s", req.Username)
		c.JSON(http.StatusConflict, gin.H{"error": "Username is already taken"})
		return
	}

	// Hash password
	log.Printf("Hashing password for user: %s", req.Email)
	hashedPassword, err := h.authService.HashPassword(req.Password)
	if err != nil {
		log.Printf("Error hashing password: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process password"})
		return
	}

	// Create user in database
	userID := uuid.New().String()
	log.Printf("Creating user in database with ID: %s", userID)
	user, err := h.hasuraService.CreateUser(ctx, services.CreateUserInput{
		ID:           userID,
		Email:        req.Email,
		Username:     req.Username,
		FullName:     req.FullName,
		PasswordHash: hashedPassword,
	})

	if err != nil {
		log.Printf("Error creating user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user account"})
		return
	}

	// Generate JWT token
	log.Printf("Generating JWT token for user: %s", user.ID)
	token, err := h.authService.GenerateToken(user.ID, user.Email)
	if err != nil {
		log.Printf("Error generating token: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate authentication token"})
		return
	}
	
	log.Printf("User registration successful: %s", user.Email)

	c.JSON(http.StatusCreated, models.AuthResponse{
		Token: token,
		User: models.User{
			ID:       user.ID,
			Email:    user.Email,
			Username: user.Username,
			FullName: user.FullName,
		},
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	log.Printf("Login request received")
	
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("Login request binding failed: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Please provide valid email and password"})
		return
	}
	
	log.Printf("Login attempt for email: %s", req.Email)

	// Get user from database
	ctx := context.Background()
	user, err := h.hasuraService.GetUserByEmail(ctx, req.Email)
	if err != nil {
		log.Printf("Error getting user during login: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to authenticate user"})
		return
	}

	if user == nil {
		log.Printf("User not found: %s", req.Email)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Verify password
	log.Printf("Verifying password for user: %s", req.Email)
	if !h.authService.CheckPassword(req.Password, user.PasswordHash) {
		log.Printf("Password verification failed for user: %s", req.Email)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// Generate JWT token
	log.Printf("Generating JWT token for login: %s", user.ID)
	token, err := h.authService.GenerateToken(user.ID, user.Email)
	if err != nil {
		log.Printf("Error generating token during login: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate authentication token"})
		return
	}
	
	log.Printf("Login successful for user: %s", user.Email)

	c.JSON(http.StatusOK, models.AuthResponse{
		Token: token,
		User: models.User{
			ID:       user.ID,
			Email:    user.Email,
			Username: user.Username,
			FullName: user.FullName,
		},
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	// Get token from header
	tokenString := c.GetHeader("Authorization")
	if tokenString == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No authentication token provided"})
		return
	}

	// Remove "Bearer " prefix
	if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
		tokenString = tokenString[7:]
	}

	// Validate token
	claims, err := h.authService.ValidateToken(tokenString)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authentication token"})
		return
	}

	// Generate new token
	newToken, err := h.authService.GenerateToken(claims.UserID, claims.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh authentication token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": newToken})
}