package ente

// PaymentProvider represents the payment provider via which a purchase was made
type App string

const (
	Photos  App = "photos"
	Auth    App = "auth"
	Locker  App = "locker"
	LlmChat App = "llmchat"
)

// Check if the app string is valid
func (a App) IsValid() bool {
	switch a {
	case Photos, Auth, Locker, LlmChat:
		return true
	}
	return false
}

// IsValidForCollection returns True if the given app type can create collections
func (a App) IsValidForCollection() bool {
	switch a {
	case Photos, Locker:
		return true
	}
	return false
}
