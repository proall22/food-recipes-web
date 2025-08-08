package handlers

import (
	"context"
	"fmt"
	"net/http"

	"recipe-backend/internal/models"
	"recipe-backend/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PaymentHandler struct {
	chapaService  *services.ChapaService
	hasuraService *services.HasuraService
}

func NewPaymentHandler(chapaService *services.ChapaService, hasuraService *services.HasuraService) *PaymentHandler {
	return &PaymentHandler{
		chapaService:  chapaService,
		hasuraService: hasuraService,
	}
}

func (h *PaymentHandler) InitializePayment(c *gin.Context) {
	var req models.PaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user ID from context
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	// Generate transaction reference
	txRef := uuid.New().String()

	// Initialize payment with Chapa
	chapaReq := services.InitializePaymentRequest{
		Amount:      fmt.Sprintf("%.2f", req.Amount),
		Currency:    "ETB",
		Email:       c.GetString("user_email"),
		FirstName:   "Recipe",
		LastName:    "User",
		TxRef:       txRef,
		CallbackURL: req.CallbackURL,
		ReturnURL:   req.ReturnURL,
		Description: "Recipe Purchase",
	}

	response, err := h.chapaService.InitializePayment(chapaReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to initialize payment"})
		return
	}

	// Create purchase record in database
	err = h.hasuraService.CreatePurchase(context.Background(), services.CreatePurchaseInput{
		UserID:        userID.(string),
		RecipeID:      req.RecipeID,
		Amount:        req.Amount,
		TransactionID: txRef,
		Status:        "pending",
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create purchase record"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"checkout_url":   response.Data.CheckoutURL,
		"transaction_id": txRef,
	})
}

func (h *PaymentHandler) VerifyPayment(c *gin.Context) {
	txRef := c.Query("tx_ref")
	if txRef == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Transaction reference required"})
		return
	}

	// Verify payment with Chapa
	response, err := h.chapaService.VerifyPayment(txRef)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to verify payment"})
		return
	}

	// Update purchase status in database
	status := "failed"
	if response.Data.Status == "success" {
		status = "completed"
	}

	err = h.hasuraService.UpdatePurchaseStatus(context.Background(), txRef, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update purchase status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":         response.Data.Status,
		"transaction_id": txRef,
		"amount":         response.Data.Amount,
	})
}

func (h *PaymentHandler) GetPaymentStatus(c *gin.Context) {
	transactionID := c.Param("transactionId")
	if transactionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Transaction ID required"})
		return
	}

	// Verify with Chapa
	response, err := h.chapaService.VerifyPayment(transactionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get payment status"})
		return
	}

	c.JSON(http.StatusOK, response.Data)
}