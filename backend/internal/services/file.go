package services

import (
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"recipe-backend/internal/config"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/google/uuid"
)

type FileService struct {
	config   *config.Config
	s3Client *s3.S3
}

func NewFileService(cfg *config.Config) *FileService {
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(cfg.AWSRegion),
		Credentials: credentials.NewStaticCredentials(
			cfg.AWSAccessKey,
			cfg.AWSSecretKey,
			"",
		),
	}))

	return &FileService{
		config:   cfg,
		s3Client: s3.New(sess),
	}
}

type UploadResult struct {
	URL      string `json:"url"`
	Key      string `json:"key"`
	FileName string `json:"file_name"`
	Size     int64  `json:"size"`
}

func (s *FileService) UploadFile(file *multipart.FileHeader, userID string) (*UploadResult, error) {
	// Validate file type
	if !s.isValidImageType(file.Filename) {
		return nil, fmt.Errorf("invalid file type. Only images are allowed")
	}

	// Validate file size (max 10MB)
	if file.Size > 10*1024*1024 {
		return nil, fmt.Errorf("file size too large. Maximum 10MB allowed")
	}

	// Open the file
	src, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer src.Close()

	// Generate unique filename
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%s/%s_%d%s", userID, uuid.New().String(), time.Now().Unix(), ext)

	// Upload to S3
	_, err = s.s3Client.PutObject(&s3.PutObjectInput{
		Bucket:      aws.String(s.config.S3Bucket),
		Key:         aws.String(filename),
		Body:        src,
		ContentType: aws.String(s.getContentType(ext)),
		ACL:         aws.String("public-read"),
	})

	if err != nil {
		return nil, err
	}

	// Generate public URL
	url := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.config.S3Bucket, s.config.AWSRegion, filename)

	return &UploadResult{
		URL:      url,
		Key:      filename,
		FileName: file.Filename,
		Size:     file.Size,
	}, nil
}

func (s *FileService) DeleteFile(key string) error {
	_, err := s.s3Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket: aws.String(s.config.S3Bucket),
		Key:    aws.String(key),
	})
	return err
}

func (s *FileService) isValidImageType(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	validExts := []string{".jpg", ".jpeg", ".png", ".gif", ".webp"}
	
	for _, validExt := range validExts {
		if ext == validExt {
			return true
		}
	}
	return false
}

func (s *FileService) getContentType(ext string) string {
	switch strings.ToLower(ext) {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	case ".webp":
		return "image/webp"
	default:
		return "application/octet-stream"
	}
}