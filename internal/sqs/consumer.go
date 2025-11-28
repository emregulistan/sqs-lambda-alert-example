package sqs

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/emregulustan/lambda-blog-project/internal/alerting"
)

// AlertPayload SQS mesajında gelen alert verisinin yapısı
type AlertPayload struct {
	Level     string                 `json:"level"`      // info, warning, error, critical
	Service   string                 `json:"service"`    // hangi servisten geldiği
	Message   string                 `json:"message"`    // alert mesajı
	Timestamp string                 `json:"timestamp"`  // alert zamanı
	Metadata  map[string]interface{} `json:"metadata"`   // ek bilgiler
}

// ParseSQSMessage SQS event record'unu parse edip AlertMessage'a dönüştürür
func ParseSQSMessage(record events.SQSMessage) (*alerting.AlertMessage, error) {
	var payload AlertPayload

	// SQS mesaj body'sini parse et
	if err := json.Unmarshal([]byte(record.Body), &payload); err != nil {
		return nil, fmt.Errorf("failed to unmarshal SQS message body: %w", err)
	}

	// Validasyon kontrolleri
	if payload.Level == "" {
		return nil, fmt.Errorf("alert level is required")
	}

	if payload.Service == "" {
		return nil, fmt.Errorf("service name is required")
	}

	if payload.Message == "" {
		return nil, fmt.Errorf("alert message is required")
	}

	// Timestamp parse et, yoksa şimdiki zamanı kullan
	var timestamp time.Time
	var err error
	if payload.Timestamp != "" {
		timestamp, err = time.Parse(time.RFC3339, payload.Timestamp)
		if err != nil {
			// Farklı format dene
			timestamp, err = time.Parse("2006-01-02T15:04:05", payload.Timestamp)
			if err != nil {
				// Parse edilemezse şimdiki zamanı kullan
				timestamp = time.Now()
			}
		}
	} else {
		timestamp = time.Now()
	}

	// AlertMessage oluştur
	alertMessage := &alerting.AlertMessage{
		Level:       payload.Level,
		Service:     payload.Service,
		Message:     payload.Message,
		Timestamp:   timestamp,
		MessageID:   record.MessageId,
		Metadata:    payload.Metadata,
	}

	return alertMessage, nil
}

// ValidateAlertLevel alert level'ın geçerli olup olmadığını kontrol eder
func ValidateAlertLevel(level string) bool {
	validLevels := map[string]bool{
		"info":     true,
		"warning":  true,
		"error":    true,
		"critical": true,
	}
	return validLevels[level]
}

