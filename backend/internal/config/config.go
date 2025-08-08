package config

import (
	"log"
	"os"
)

type Config struct {
	HasuraEndpoint   string
	HasuraAdminSecret string
	JWTSecret        string
	ChapaSecretKey   string
	DatabaseURL      string
	AWSRegion        string
	AWSAccessKey     string
	AWSSecretKey     string
	S3Bucket         string
}

func New() *Config {
	cfg := &Config{
		HasuraEndpoint:    getEnv("HASURA_ENDPOINT", "http://localhost:8080/v1/graphql"),
		HasuraAdminSecret: getEnv("HASURA_ADMIN_SECRET", "myadminsecretkey"),
		JWTSecret:         getEnv("JWT_SECRET", "9f3d57c29f03be8f4ad88b19c495345f5d0a219b9f78df6129ab7f60a76d879d"),
		ChapaSecretKey:    getEnv("CHAPA_SECRET_KEY", ""),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://postgres:postgrespassword@localhost:5432/recipes_db?sslmode=disable"),
		AWSRegion:         getEnv("AWS_REGION", "us-east-1"),
		AWSAccessKey:      getEnv("AWS_ACCESS_KEY", ""),
		AWSSecretKey:      getEnv("AWS_SECRET_KEY", ""),
		S3Bucket:          getEnv("S3_BUCKET", "recipe-images"),
	}
	
	// Validate critical configuration
	if cfg.HasuraEndpoint == "" {
		log.Fatal("HASURA_ENDPOINT is required")
	}
	if cfg.HasuraAdminSecret == "" {
		log.Fatal("HASURA_ADMIN_SECRET is required")
	}
	if len(cfg.JWTSecret) < 32 {
		log.Fatal("JWT_SECRET must be at least 32 characters long")
	}
	
	return cfg
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		log.Printf("Using environment variable %s", key)
		return value
	}
	log.Printf("Using default value for %s", key)
	return defaultValue
}