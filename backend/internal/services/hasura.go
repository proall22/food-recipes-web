package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"recipe-backend/internal/config"
)

type HasuraService struct {
	config     *config.Config
	httpClient *http.Client
}

func NewHasuraService(cfg *config.Config) *HasuraService {
	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	return &HasuraService{
		config:     cfg,
		httpClient: client,
	}
}

// GraphQL request structure
type GraphQLRequest struct {
	Query     string                 `json:"query"`
	Variables map[string]interface{} `json:"variables,omitempty"`
}

type GraphQLResponse struct {
	Data   json.RawMessage `json:"data"`
	Errors []struct {
		Message string `json:"message"`
	} `json:"errors"`
}

// Execute GraphQL query
func (s *HasuraService) ExecuteQuery(ctx context.Context, query string, variables map[string]interface{}) (*GraphQLResponse, error) {
	log.Printf("Executing GraphQL query to: %s", s.config.HasuraEndpoint)
	log.Printf("Query: %s", query)
	log.Printf("Variables: %+v", variables)

	reqBody := GraphQLRequest{
		Query:     query,
		Variables: variables,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", s.config.HasuraEndpoint, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Hasura-Admin-Secret", s.config.HasuraAdminSecret)
	
	log.Printf("Request headers: Content-Type: application/json, X-Hasura-Admin-Secret: %s", s.config.HasuraAdminSecret)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		log.Printf("HTTP request failed: %v", err)
		return nil, fmt.Errorf("failed to execute HTTP request to Hasura: %w", err)
	}
	defer resp.Body.Close()
	
	log.Printf("HTTP response status: %d", resp.StatusCode)

	var graphqlResp GraphQLResponse
	if err := json.NewDecoder(resp.Body).Decode(&graphqlResp); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return nil, fmt.Errorf("failed to decode GraphQL response: %w", err)
	}
	
	log.Printf("GraphQL response: %+v", graphqlResp)

	if len(graphqlResp.Errors) > 0 {
		log.Printf("GraphQL errors: %+v", graphqlResp.Errors)
		return nil, fmt.Errorf("GraphQL error: %s", graphqlResp.Errors[0].Message)
	}

	return &graphqlResp, nil
}

// User operations
func (s *HasuraService) CreateUser(ctx context.Context, user CreateUserInput) (*User, error) {
	log.Printf("Creating user with data: %+v", user)
	
	query := `
		mutation CreateUser($user: users_insert_input!) {
			insert_users_one(object: $user) {
				id
				email
				username
				full_name
				created_at
			}
		}
	`

	variables := map[string]interface{}{
		"user": map[string]interface{}{
			"id":            user.ID,
			"email":         user.Email,
			"username":      user.Username,
			"full_name":     user.FullName,
			"password_hash": user.PasswordHash,
		},
	}

	resp, err := s.ExecuteQuery(ctx, query, variables)
	if err != nil {
		log.Printf("Failed to execute create user query: %v", err)
		return nil, fmt.Errorf("failed to create user in database: %w", err)
	}

	var result struct {
		InsertUsersOne *User `json:"insert_users_one"`
	}

	if err := json.Unmarshal(resp.Data, &result); err != nil {
		log.Printf("Failed to unmarshal create user response: %v", err)
		return nil, fmt.Errorf("failed to parse create user response: %w", err)
	}

	if result.InsertUsersOne == nil {
		log.Printf("No user data returned from create mutation")
		return nil, fmt.Errorf("user creation failed: no data returned from database")
	}
	
	log.Printf("User created successfully: %+v", result.InsertUsersOne)

	return result.InsertUsersOne, nil
}

func (s *HasuraService) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	query := `
		query GetUserByEmail($email: String!) {
			users(where: {email: {_eq: $email}}) {
				id
				email
				username
				full_name
				password_hash
				avatar_url
				bio
				created_at
				updated_at
			}
		}
	`

	variables := map[string]interface{}{
		"email": email,
	}

	resp, err := s.ExecuteQuery(ctx, query, variables)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	var result struct {
		Users []User `json:"users"`
	}

	if err := json.Unmarshal(resp.Data, &result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if len(result.Users) == 0 {
		return nil, nil
	}

	return &result.Users[0], nil
}

func (s *HasuraService) GetUserByUsername(ctx context.Context, username string) (*User, error) {
	query := `
		query GetUserByUsername($username: String!) {
			users(where: {username: {_eq: $username}}) {
				id
				email
				username
				full_name
				password_hash
				avatar_url
				bio
				created_at
				updated_at
			}
		}
	`

	variables := map[string]interface{}{
		"username": username,
	}

	resp, err := s.ExecuteQuery(ctx, query, variables)
	if err != nil {
		return nil, fmt.Errorf("failed to get user by username: %w", err)
	}

	var result struct {
		Users []User `json:"users"`
	}

	if err := json.Unmarshal(resp.Data, &result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if len(result.Users) == 0 {
		return nil, nil
	}

	return &result.Users[0], nil
}

// Purchase operations
func (s *HasuraService) CreatePurchase(ctx context.Context, purchase CreatePurchaseInput) error {
	query := `
		mutation CreatePurchase($purchase: purchases_insert_input!) {
			insert_purchases_one(object: $purchase) {
				id
			}
		}
	`

	variables := map[string]interface{}{
		"purchase": map[string]interface{}{
			"user_id":        purchase.UserID,
			"recipe_id":      purchase.RecipeID,
			"amount":         purchase.Amount,
			"transaction_id": purchase.TransactionID,
			"status":         purchase.Status,
		},
	}

	_, err := s.ExecuteQuery(ctx, query, variables)
	return err
}

func (s *HasuraService) UpdatePurchaseStatus(ctx context.Context, transactionID, status string) error {
	query := `
		mutation UpdatePurchaseStatus($transaction_id: String!, $status: String!) {
			update_purchases(
				where: {transaction_id: {_eq: $transaction_id}}, 
				_set: {status: $status}
			) {
				affected_rows
			}
		}
	`

	variables := map[string]interface{}{
		"transaction_id": transactionID,
		"status":         status,
	}

	_, err := s.ExecuteQuery(ctx, query, variables)
	return err
}

// Types for GraphQL operations
type User struct {
	ID           string `json:"id"`
	Email        string `json:"email"`
	Username     string `json:"username"`
	FullName     string `json:"full_name"`
	PasswordHash string `json:"password_hash"`
	AvatarURL    string `json:"avatar_url,omitempty"`
	Bio          string `json:"bio,omitempty"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at,omitempty"`
}

type CreateUserInput struct {
	ID           string `json:"id"`
	Email        string `json:"email"`
	Username     string `json:"username"`
	FullName     string `json:"full_name"`
	PasswordHash string `json:"password_hash"`
}

type CreatePurchaseInput struct {
	UserID        string  `json:"user_id"`
	RecipeID      string  `json:"recipe_id"`
	Amount        float64 `json:"amount"`
	TransactionID string  `json:"transaction_id"`
	Status        string  `json:"status"`
}