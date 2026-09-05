package handler

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type APIKeyHandler struct {
	DB *sql.DB
}

func NewAPIKeyHandler(db *sql.DB) *APIKeyHandler {
	return &APIKeyHandler{DB: db}
}

// CreateKey generates a new API key for the user
func (h *APIKeyHandler) CreateKey(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req struct {
		Name string `json:"name" binding:"required,max=64"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Generate random key
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate key"})
		return
	}
	key := "gkp_" + hex.EncodeToString(b)

	var keyID int64
	err := h.DB.QueryRow(
		"INSERT INTO api_keys (user_id, key, name, is_active) VALUES ($1, $2, $3, true) RETURNING id",
		userID, key, req.Name,
	).Scan(&keyID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create API key"})
		return
	}

	// Return full key only once
	c.JSON(http.StatusCreated, gin.H{
		"id":         keyID,
		"name":       req.Name,
		"key":        key,
		"is_active":  true,
		"created_at": time.Now(),
	})
}

// ListKeys returns all API keys for the user (masked)
func (h *APIKeyHandler) ListKeys(c *gin.Context) {
	userID := c.GetInt64("user_id")

	rows, err := h.DB.Query(`
		SELECT id, name, key, last_used, is_active, created_at
		FROM api_keys WHERE user_id = $1 ORDER BY created_at DESC
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var keys []gin.H
	for rows.Next() {
		var keyStr string
		var entry struct {
			ID       int64      `json:"id"`
			Name     string     `json:"name"`
			LastUsed *time.Time `json:"last_used"`
			IsActive bool       `json:"is_active"`
			CreatedAt time.Time `json:"created_at"`
		}
		if err := rows.Scan(&entry.ID, &entry.Name, &keyStr, &entry.LastUsed, &entry.IsActive, &entry.CreatedAt); err != nil {
			continue
		}
		// Mask key
		masked := keyStr[:8] + "..." + keyStr[len(keyStr)-4:]
		keys = append(keys, gin.H{
			"id":         entry.ID,
			"name":       entry.Name,
			"key_masked": masked,
			"last_used":  entry.LastUsed,
			"is_active":  entry.IsActive,
			"created_at": entry.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"api_keys": keys})
}

// RevokeKey deactivates an API key
func (h *APIKeyHandler) RevokeKey(c *gin.Context) {
	userID := c.GetInt64("user_id")
	keyID := c.Param("id")

	result, err := h.DB.Exec(
		"UPDATE api_keys SET is_active = false WHERE id = $1 AND user_id = $2",
		keyID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "key not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "API key revoked"})
}
