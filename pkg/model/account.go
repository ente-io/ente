package model

import "cli-go/internal/api"

type AccountInfo struct {
	Email     string    `json:"email" binding:"required"`
	UserID    int64     `json:"userID" binding:"required"`
	App       api.App   `json:"app" binding:"required"`
	MasterKey EncString `json:"masterKey" binding:"required"`
	Token     EncString `json:"token" binding:"required"`
}
