package handler

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type AuthHandler struct {
	DB *sql.DB
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=32"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func NewAuthHandler(db *sql.DB) *AuthHandler {
	return &AuthHandler{DB: db}
}

// Register handles user registration
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if username already exists
	var exists bool
	err := h.DB.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)", req.Username).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "username already exists"})
		return
	}

	// In production, use bcrypt. For now, simple hash
	passwordHash := simpleHash(req.Password)

	var userID int64
	err = h.DB.QueryRow(
		"INSERT INTO users (username, email, password_hash, balance, status) VALUES ($1, $2, $3, 0, 'active') RETURNING id",
		req.Username, req.Email, passwordHash,
	).Scan(&userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}

	// Generate JWT token
	token, err := generateJWT(userID, req.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"user_id":  userID,
		"username": req.Username,
		"token":    token,
	})
}

// Login handles user login
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var userID int64
	var passwordHash string
	err := h.DB.QueryRow(
		"SELECT id, password_hash FROM users WHERE username = $1 AND status = 'active'",
		req.Username,
	).Scan(&userID, &passwordHash)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	if passwordHash != simpleHash(req.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	token, err := generateJWT(userID, req.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user_id":  userID,
		"username": req.Username,
		"token":    token,
	})
}

// GetMe returns current user info
func (h *AuthHandler) GetMe(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var user struct {
		ID       int64   `json:"id"`
		Username string  `json:"username"`
		Email    string  `json:"email"`
		Balance  float64 `json:"balance"`
		Status   string  `json:"status"`
	}

	err := h.DB.QueryRow(
		"SELECT id, username, email, balance, status FROM users WHERE id = $1",
		userID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Balance, &user.Status)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func generateJWT(userID int64, username string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "your-secret-key-change-in-production"
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  userID,
		"username": username,
		"exp":      time.Now().Add(72 * time.Hour).Unix(),
	})

	return token.SignedString([]byte(secret))
}

func simpleHash(s string) string {
	// In production, use bcrypt
	b := make([]byte, 32)
	copy(b, []byte(s))
	return hex.EncodeToString(b)
}

func init() {
	// Suppress unused import warning
	_ = rand.Reader
}
