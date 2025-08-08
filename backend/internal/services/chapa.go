package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"recipe-backend/internal/config"
)

type ChapaService struct {
	config     *config.Config
	httpClient *http.Client
	baseURL    string
}

func NewChapaService(cfg *config.Config) *ChapaService {
	return &ChapaService{
		config:     cfg,
		httpClient: &http.Client{},
		baseURL:    "https://api.chapa.co/v1",
	}
}

type InitializePaymentRequest struct {
	Amount      string `json:"amount"`
	Currency    string `json:"currency"`
	Email       string `json:"email"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	TxRef       string `json:"tx_ref"`
	CallbackURL string `json:"callback_url"`
	ReturnURL   string `json:"return_url"`
	Description string `json:"description"`
}

type InitializePaymentResponse struct {
	Message string `json:"message"`
	Status  string `json:"status"`
	Data    struct {
		CheckoutURL string `json:"checkout_url"`
	} `json:"data"`
}

type VerifyPaymentResponse struct {
	Message string `json:"message"`
	Status  string `json:"status"`
	Data    struct {
		Amount      string `json:"amount"`
		Currency    string `json:"currency"`
		Status      string `json:"status"`
		Reference   string `json:"reference"`
		TxRef       string `json:"tx_ref"`
		ChargeID    string `json:"charge_id"`
		CreatedAt   string `json:"created_at"`
		UpdatedAt   string `json:"updated_at"`
	} `json:"data"`
}

func (s *ChapaService) InitializePayment(req InitializePaymentRequest) (*InitializePaymentResponse, error) {
	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequest("POST", s.baseURL+"/transaction/initialize", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Authorization", "Bearer "+s.config.ChapaSecretKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var response InitializePaymentResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("chapa API error: %s", response.Message)
	}

	return &response, nil
}

func (s *ChapaService) VerifyPayment(txRef string) (*VerifyPaymentResponse, error) {
	url := fmt.Sprintf("%s/transaction/verify/%s", s.baseURL, txRef)

	httpReq, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Authorization", "Bearer "+s.config.ChapaSecretKey)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var response VerifyPaymentResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("chapa API error: %s", response.Message)
	}

	return &response, nil
}