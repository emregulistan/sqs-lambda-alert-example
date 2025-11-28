package alerting

import (
	"context"
	"testing"
	"time"
)

func TestConsoleNotifier(t *testing.T) {
	notifier := NewConsoleNotifier()

	alert := &AlertMessage{
		Level:     "info",
		Service:   "test-service",
		Message:   "Test alert message",
		Timestamp: time.Now(),
		MessageID: "test-message-id",
		Metadata: map[string]interface{}{
			"key": "value",
		},
	}

	err := notifier.SendAlert(context.Background(), alert)
	if err != nil {
		t.Errorf("ConsoleNotifier.SendAlert() error = %v", err)
	}
}

func TestSlackNotifier_getLevelColor(t *testing.T) {
	notifier := NewSlackNotifier("https://example.com/webhook")

	tests := []struct {
		level string
		want  string
	}{
		{"info", "#36a64f"},
		{"warning", "#ff9800"},
		{"error", "#f44336"},
		{"critical", "#9c27b0"},
		{"unknown", "#808080"},
	}

	for _, tt := range tests {
		t.Run(tt.level, func(t *testing.T) {
			if got := notifier.getLevelColor(tt.level); got != tt.want {
				t.Errorf("getLevelColor(%v) = %v, want %v", tt.level, got, tt.want)
			}
		})
	}
}

func TestSlackNotifier_getLevelIcon(t *testing.T) {
	notifier := NewSlackNotifier("https://example.com/webhook")

	tests := []struct {
		level string
		want  string
	}{
		{"info", ":information_source:"},
		{"warning", ":warning:"},
		{"error", ":x:"},
		{"critical", ":fire:"},
		{"unknown", ":bell:"},
	}

	for _, tt := range tests {
		t.Run(tt.level, func(t *testing.T) {
			if got := notifier.getLevelIcon(tt.level); got != tt.want {
				t.Errorf("getLevelIcon(%v) = %v, want %v", tt.level, got, tt.want)
			}
		})
	}
}

func TestAlertMessage(t *testing.T) {
	alert := &AlertMessage{
		Level:     "error",
		Service:   "api-gateway",
		Message:   "High latency detected",
		Timestamp: time.Now(),
		MessageID: "msg-123",
		Metadata: map[string]interface{}{
			"latency_ms": 5000,
			"endpoint":   "/api/users",
		},
	}

	if alert.Level != "error" {
		t.Errorf("Level = %v, want error", alert.Level)
	}

	if alert.Service != "api-gateway" {
		t.Errorf("Service = %v, want api-gateway", alert.Service)
	}

	if alert.MessageID != "msg-123" {
		t.Errorf("MessageID = %v, want msg-123", alert.MessageID)
	}

	if len(alert.Metadata) != 2 {
		t.Errorf("Metadata length = %v, want 2", len(alert.Metadata))
	}
}

// Mock HTTP server için test (opsiyonel, gerçek HTTP testleri için)
// Bu test gerçek bir Slack webhook'a istek gönderir, bu yüzden normalde skip edilebilir
func TestSlackNotifier_SendAlert_Integration(t *testing.T) {
	t.Skip("Integration test - requires valid Slack webhook URL")

	webhookURL := "YOUR_WEBHOOK_URL_HERE"
	notifier := NewSlackNotifier(webhookURL)

	alert := &AlertMessage{
		Level:     "info",
		Service:   "test-service",
		Message:   "Integration test alert",
		Timestamp: time.Now(),
		MessageID: "test-integration-msg",
	}

	ctx := context.Background()
	err := notifier.SendAlert(ctx, alert)
	if err != nil {
		t.Errorf("SlackNotifier.SendAlert() error = %v", err)
	}
}

