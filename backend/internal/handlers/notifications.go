package handlers

import (
	"context"
	"fmt"
	"net/http"
	"net/smtp"
	"os"
	"strings"
	"text/template"

	"recipe-backend/internal/services"

	"github.com/gin-gonic/gin"
)

type NotificationHandler struct {
	hasuraService *services.HasuraService
}

func NewNotificationHandler(hasuraService *services.HasuraService) *NotificationHandler {
	return &NotificationHandler{
		hasuraService: hasuraService,
	}
}

type EmailNotificationRequest struct {
	RecipientEmail string                 `json:"recipient_email" binding:"required,email"`
	Type           string                 `json:"type" binding:"required"`
	Data           map[string]interface{} `json:"data"`
}

func (h *NotificationHandler) SendEmailNotification(c *gin.Context) {
	var req EmailNotificationRequest
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

	// Generate email content based on type
	subject, body, err := h.generateEmailContent(req.Type, req.Data)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email type or data"})
		return
	}

	// Queue email for sending
	err = h.queueEmail(context.Background(), req.RecipientEmail, subject, body, req.Type, req.Data)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to queue email"})
		return
	}

	// Send email immediately (in production, this would be handled by a background worker)
	go h.sendEmail(req.RecipientEmail, subject, body)

	c.JSON(http.StatusOK, gin.H{"message": "Email notification sent successfully"})
}

func (h *NotificationHandler) generateEmailContent(emailType string, data map[string]interface{}) (string, string, error) {
	templates := map[string]struct {
		subject  string
		template string
	}{
		"welcome": {
			subject: "Welcome to RecipeHub!",
			template: `
Hello {{.user_name}},

Welcome to RecipeHub! We're excited to have you join our community of food lovers.

Start exploring amazing recipes, share your own culinary creations, and connect with fellow food enthusiasts.

Happy cooking!
The RecipeHub Team
			`,
		},
		"recipe_liked": {
			subject: "Someone liked your recipe!",
			template: `
Hello,

Great news! {{.liked_by_name}} (@{{.liked_by_username}}) just liked your recipe "{{.recipe_title}}".

View your recipe: https://recipehub.com/recipes/{{.recipe_id}}

Keep sharing those amazing recipes!
The RecipeHub Team
			`,
		},
		"recipe_commented": {
			subject: "New comment on your recipe",
			template: `
Hello,

{{.commented_by_name}} (@{{.commented_by_username}}) left a comment on your recipe "{{.recipe_title}}":

"{{.comment}}"

View the full conversation: https://recipehub.com/recipes/{{.recipe_id}}

Happy cooking!
The RecipeHub Team
			`,
		},
		"recipe_rated": {
			subject: "Your recipe received a new rating!",
			template: `
Hello,

{{.rated_by_name}} (@{{.rated_by_username}}) gave your recipe "{{.recipe_title}}" a {{.rating}}-star rating!

View your recipe: https://recipehub.com/recipes/{{.recipe_id}}

Keep up the great work!
The RecipeHub Team
			`,
		},
		"recipe_purchased": {
			subject: "Your recipe was purchased!",
			template: `
Hello,

Congratulations! {{.purchased_by_name}} (@{{.purchased_by_username}}) just purchased your premium recipe "{{.recipe_title}}" for ${{.amount}}.

View your recipe: https://recipehub.com/recipes/{{.recipe_id}}

Keep creating amazing premium content!
The RecipeHub Team
			`,
		},
		"purchase_confirmation": {
			subject: "Purchase Confirmation - RecipeHub",
			template: `
Hello,

Thank you for your purchase! You now have access to the premium recipe "{{.recipe_title}}" by {{.seller_name}}.

Amount paid: ${{.amount}}

View your recipe: https://recipehub.com/recipes/{{.recipe_id}}

Enjoy cooking!
The RecipeHub Team
			`,
		},
	}

	emailTemplate, exists := templates[emailType]
	if !exists {
		return "", "", fmt.Errorf("unknown email type: %s", emailType)
	}

	// Parse and execute template
	tmpl, err := template.New("email").Parse(emailTemplate.template)
	if err != nil {
		return "", "", err
	}

	var body strings.Builder
	err = tmpl.Execute(&body, data)
	if err != nil {
		return "", "", err
	}

	return emailTemplate.subject, body.String(), nil
}

func (h *NotificationHandler) queueEmail(ctx context.Context, recipientEmail, subject, body, templateType string, templateData map[string]interface{}) error {
	query := `
		mutation QueueEmail($email: email_notifications_insert_input!) {
			insert_email_notifications_one(object: $email) {
				id
			}
		}
	`

	variables := map[string]interface{}{
		"email": map[string]interface{}{
			"recipient_email": recipientEmail,
			"subject":         subject,
			"body":            body,
			"template_type":   templateType,
			"template_data":   templateData,
			"status":          "pending",
		},
	}

	_, err := h.hasuraService.ExecuteQuery(ctx, query, variables)
	return err
}

func (h *NotificationHandler) sendEmail(to, subject, body string) error {
	// Email configuration from environment variables
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")
	fromEmail := os.Getenv("FROM_EMAIL")

	if smtpHost == "" || smtpPort == "" || smtpUser == "" || smtpPass == "" {
		// If SMTP is not configured, just log the email (for development)
		fmt.Printf("EMAIL NOTIFICATION:\nTo: %s\nSubject: %s\nBody: %s\n", to, subject, body)
		return nil
	}

	// Create message
	msg := []byte(fmt.Sprintf("To: %s\r\nSubject: %s\r\n\r\n%s\r\n", to, subject, body))

	// SMTP authentication
	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)

	// Send email
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, fromEmail, []string{to}, msg)
	if err != nil {
		fmt.Printf("Failed to send email: %v\n", err)
		return err
	}

	fmt.Printf("Email sent successfully to %s\n", to)
	return nil
}

// Background worker to process email queue (this would run as a separate service in production)
func (h *NotificationHandler) ProcessEmailQueue() {
	// This would be implemented as a background worker
	// For now, emails are sent immediately in the SendEmailNotification handler
}