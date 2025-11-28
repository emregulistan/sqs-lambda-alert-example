package sqs

import (
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
)

func TestParseSQSMessage(t *testing.T) {
	tests := []struct {
		name    string
		record  events.SQSMessage
		wantErr bool
	}{
		{
			name: "Valid message",
			record: events.SQSMessage{
				MessageId: "test-message-1",
				Body:      `{"level":"info","service":"test-service","message":"Test message","timestamp":"2025-11-28T10:00:00Z"}`,
			},
			wantErr: false,
		},
		{
			name: "Valid message without timestamp",
			record: events.SQSMessage{
				MessageId: "test-message-2",
				Body:      `{"level":"error","service":"test-service","message":"Error occurred"}`,
			},
			wantErr: false,
		},
		{
			name: "Missing level",
			record: events.SQSMessage{
				MessageId: "test-message-3",
				Body:      `{"service":"test-service","message":"Test message"}`,
			},
			wantErr: true,
		},
		{
			name: "Missing service",
			record: events.SQSMessage{
				MessageId: "test-message-4",
				Body:      `{"level":"info","message":"Test message"}`,
			},
			wantErr: true,
		},
		{
			name: "Missing message",
			record: events.SQSMessage{
				MessageId: "test-message-5",
				Body:      `{"level":"info","service":"test-service"}`,
			},
			wantErr: true,
		},
		{
			name: "Invalid JSON",
			record: events.SQSMessage{
				MessageId: "test-message-6",
				Body:      `{invalid json}`,
			},
			wantErr: true,
		},
		{
			name: "With metadata",
			record: events.SQSMessage{
				MessageId: "test-message-7",
				Body:      `{"level":"warning","service":"api","message":"High latency","metadata":{"latency_ms":5000}}`,
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			alert, err := ParseSQSMessage(tt.record)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseSQSMessage() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr {
				if alert == nil {
					t.Error("Expected alert message, got nil")
					return
				}

				if alert.MessageID != tt.record.MessageId {
					t.Errorf("MessageID = %v, want %v", alert.MessageID, tt.record.MessageId)
				}

				if alert.Timestamp.IsZero() {
					t.Error("Timestamp should not be zero")
				}
			}
		})
	}
}

func TestValidateAlertLevel(t *testing.T) {
	tests := []struct {
		level string
		want  bool
	}{
		{"info", true},
		{"warning", true},
		{"error", true},
		{"critical", true},
		{"invalid", false},
		{"INFO", false},
		{"", false},
	}

	for _, tt := range tests {
		t.Run(tt.level, func(t *testing.T) {
			if got := ValidateAlertLevel(tt.level); got != tt.want {
				t.Errorf("ValidateAlertLevel(%v) = %v, want %v", tt.level, got, tt.want)
			}
		})
	}
}

func TestAlertPayloadTimestampParsing(t *testing.T) {
	tests := []struct {
		name      string
		timestamp string
		wantErr   bool
	}{
		{
			name:      "RFC3339 format",
			timestamp: "2025-11-28T10:00:00Z",
			wantErr:   false,
		},
		{
			name:      "Alternative format",
			timestamp: "2025-11-28T10:00:00",
			wantErr:   false,
		},
		{
			name:      "Empty timestamp",
			timestamp: "",
			wantErr:   false, // Should use current time
		},
		{
			name:      "Invalid timestamp",
			timestamp: "invalid-date",
			wantErr:   false, // Should fall back to current time
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			record := events.SQSMessage{
				MessageId: "test-message",
				Body:      `{"level":"info","service":"test","message":"Test"}`,
			}

			if tt.timestamp != "" {
				record.Body = `{"level":"info","service":"test","message":"Test","timestamp":"` + tt.timestamp + `"}`
			}

			alert, err := ParseSQSMessage(record)
			if tt.wantErr && err == nil {
				t.Error("Expected error, got nil")
			}

			if !tt.wantErr {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
				}
				if alert != nil {
					// Timestamp zero olmamalı ve mantıklı bir aralıkta olmalı (son 1 yıl içinde veya gelecekte)
					if alert.Timestamp.IsZero() {
						t.Error("Timestamp should not be zero")
					}
					// Geçmiş timestamp'ler de geçerli olabilir (alert'ler geçmişte olabilir)
					// Sadece çok eski veya çok gelecekteki timestamp'leri kontrol et
					oneYearAgo := time.Now().Add(-365 * 24 * time.Hour)
					oneYearAhead := time.Now().Add(365 * 24 * time.Hour)
					if alert.Timestamp.Before(oneYearAgo) || alert.Timestamp.After(oneYearAhead) {
						t.Errorf("Timestamp is out of reasonable range: %v", alert.Timestamp)
					}
				}
			}
		})
	}
}

