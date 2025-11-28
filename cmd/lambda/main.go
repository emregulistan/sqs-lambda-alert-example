package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/emregulustan/lambda-blog-project/internal/alerting"
	"github.com/emregulustan/lambda-blog-project/internal/sqs"
)

var (
	notifier alerting.Notifier
)

func init() {
	// Slack webhook URL'i environment variable'dan al
	slackWebhookURL := os.Getenv("SLACK_WEBHOOK_URL")
	if slackWebhookURL == "" {
		log.Println("WARN: SLACK_WEBHOOK_URL is not set, using console notifier")
		notifier = alerting.NewConsoleNotifier()
	} else {
		notifier = alerting.NewSlackNotifier(slackWebhookURL)
	}
}

// HandleRequest Lambda fonksiyonunun ana handler'ı
func HandleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	log.Printf("Received %d SQS messages", len(sqsEvent.Records))

	for i, record := range sqsEvent.Records {
		log.Printf("Processing message %d/%d: MessageID=%s", i+1, len(sqsEvent.Records), record.MessageId)

		// SQS mesajını parse et
		alertMessage, err := sqs.ParseSQSMessage(record)
		if err != nil {
			log.Printf("ERROR: Failed to parse message %s: %v", record.MessageId, err)
			// DLQ'ya gitmesi için error döndür
			return fmt.Errorf("failed to parse message: %w", err)
		}

		log.Printf("Parsed alert: Level=%s, Service=%s, Message=%s",
			alertMessage.Level, alertMessage.Service, alertMessage.Message)

		// Alert'i notification sistemine gönder
		if err := notifier.SendAlert(ctx, alertMessage); err != nil {
			log.Printf("ERROR: Failed to send alert for message %s: %v", record.MessageId, err)
			return fmt.Errorf("failed to send alert: %w", err)
		}

		log.Printf("Successfully processed message %s", record.MessageId)
	}

	return nil
}

func main() {
	// Lambda runtime'ı başlat
	lambda.Start(HandleRequest)
}

