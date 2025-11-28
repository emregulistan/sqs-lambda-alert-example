package alerting

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

// AlertMessage alert mesajının genel yapısı
type AlertMessage struct {
	Level     string                 `json:"level"`
	Service   string                 `json:"service"`
	Message   string                 `json:"message"`
	Timestamp time.Time              `json:"timestamp"`
	MessageID string                 `json:"message_id"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// Notifier alert gönderme için interface
// Bu interface sayesinde farklı notification sistemleri (Slack, Email, PagerDuty, vb.) eklenebilir
type Notifier interface {
	SendAlert(ctx context.Context, alert *AlertMessage) error
}

// SlackNotifier Slack webhook ile alert gönderen implementasyon
type SlackNotifier struct {
	webhookURL string
	httpClient *http.Client
}

// NewSlackNotifier yeni bir Slack notifier oluşturur
func NewSlackNotifier(webhookURL string) *SlackNotifier {
	return &SlackNotifier{
		webhookURL: webhookURL,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// SlackMessage Slack'e gönderilecek mesajın yapısı
type SlackMessage struct {
	Text        string            `json:"text"`
	Username    string            `json:"username,omitempty"`
	IconEmoji   string            `json:"icon_emoji,omitempty"`
	Attachments []SlackAttachment `json:"attachments,omitempty"`
}

// SlackAttachment Slack mesajına eklenen zengin içerik
type SlackAttachment struct {
	Color      string       `json:"color,omitempty"`
	Title      string       `json:"title,omitempty"`
	Text       string       `json:"text,omitempty"`
	Fields     []SlackField `json:"fields,omitempty"`
	Footer     string       `json:"footer,omitempty"`
	FooterIcon string       `json:"footer_icon,omitempty"`
	Timestamp  int64        `json:"ts,omitempty"`
}

// SlackField Slack attachment içindeki alan
type SlackField struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

// SendAlert Slack'e alert gönderir
func (s *SlackNotifier) SendAlert(ctx context.Context, alert *AlertMessage) error {
	// Alert level'a göre renk belirle
	color := s.getLevelColor(alert.Level)
	icon := s.getLevelIcon(alert.Level)

	// Slack mesajını oluştur
	slackMsg := SlackMessage{
		Username:  "Alert Bot",
		IconEmoji: icon,
		Attachments: []SlackAttachment{
			{
				Color: color,
				Title: fmt.Sprintf("%s Alert from %s", alert.Level, alert.Service),
				Text:  alert.Message,
				Fields: []SlackField{
					{
						Title: "Service",
						Value: alert.Service,
						Short: true,
					},
					{
						Title: "Level",
						Value: alert.Level,
						Short: true,
					},
					{
						Title: "Message ID",
						Value: alert.MessageID,
						Short: false,
					},
				},
				Footer:    "Lambda Alert System",
				FooterIcon: "https://platform.slack-edge.com/img/default_application_icon.png",
				Timestamp: alert.Timestamp.Unix(),
			},
		},
	}

	// Metadata varsa ekle
	if len(alert.Metadata) > 0 {
		metadataJSON, _ := json.MarshalIndent(alert.Metadata, "", "  ")
		slackMsg.Attachments[0].Fields = append(slackMsg.Attachments[0].Fields, SlackField{
			Title: "Metadata",
			Value: fmt.Sprintf("```%s```", string(metadataJSON)),
			Short: false,
		})
	}

	// JSON'a serialize et
	payload, err := json.Marshal(slackMsg)
	if err != nil {
		return fmt.Errorf("failed to marshal slack message: %w", err)
	}

	// HTTP request oluştur
	req, err := http.NewRequestWithContext(ctx, "POST", s.webhookURL, bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	// Request gönder
	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Response kontrol et
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("slack returned non-OK status: %d, body: %s", resp.StatusCode, string(body))
	}

	log.Printf("Successfully sent alert to Slack: %s", alert.MessageID)
	return nil
}

// getLevelColor alert level'a göre Slack rengi döndürür
func (s *SlackNotifier) getLevelColor(level string) string {
	colors := map[string]string{
		"info":     "#36a64f", // yeşil
		"warning":  "#ff9800", // turuncu
		"error":    "#f44336", // kırmızı
		"critical": "#9c27b0", // mor
	}
	if color, ok := colors[level]; ok {
		return color
	}
	return "#808080" // gri (varsayılan)
}

// getLevelIcon alert level'a göre emoji döndürür
func (s *SlackNotifier) getLevelIcon(level string) string {
	icons := map[string]string{
		"info":     ":information_source:",
		"warning":  ":warning:",
		"error":    ":x:",
		"critical": ":fire:",
	}
	if icon, ok := icons[level]; ok {
		return icon
	}
	return ":bell:"
}

// ConsoleNotifier console'a log yazan basit bir notifier (test için)
type ConsoleNotifier struct{}

// NewConsoleNotifier yeni bir console notifier oluşturur
func NewConsoleNotifier() *ConsoleNotifier {
	return &ConsoleNotifier{}
}

// SendAlert console'a alert yazar
func (c *ConsoleNotifier) SendAlert(ctx context.Context, alert *AlertMessage) error {
	log.Printf("=== ALERT ===")
	log.Printf("Level: %s", alert.Level)
	log.Printf("Service: %s", alert.Service)
	log.Printf("Message: %s", alert.Message)
	log.Printf("Timestamp: %s", alert.Timestamp.Format(time.RFC3339))
	log.Printf("MessageID: %s", alert.MessageID)
	if len(alert.Metadata) > 0 {
		metadataJSON, _ := json.MarshalIndent(alert.Metadata, "", "  ")
		log.Printf("Metadata: %s", string(metadataJSON))
	}
	log.Printf("=============")
	return nil
}

