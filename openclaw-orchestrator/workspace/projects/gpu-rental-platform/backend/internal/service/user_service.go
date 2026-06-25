package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gpucloud/internal/database"
	"gpucloud/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	db  *database.DB
	rdb *database.Redis
}

func NewUserService(db *database.DB, rdb *database.Redis) *UserService {
	return &UserService{db: db, rdb: rdb}
}

func (s *UserService) Register(ctx context.Context, req models.CreateUserRequest) (*models.User, error) {
	// Check if email exists
	var exists bool
	err := s.db.Pool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", req.Email).Scan(&exists)
	if err != nil {
		return nil, fmt.Errorf("check email: %w", err)
	}
	if exists {
		return nil, errors.New("email already registered")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	// Create user and wallet in transaction
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var user models.User
	err = tx.QueryRow(ctx,
		`INSERT INTO users (username, email, phone, password_hash)
		 VALUES ($1, $2, $3, $4)
		 RETURNING id, username, email, phone, status, created_at`,
		req.Username, req.Email, req.Phone, string(hashedPassword),
	).Scan(&user.ID, &user.Username, &user.Email, &user.Phone, &user.Status, &user.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	// Create wallet with welcome bonus
	_, err = tx.Exec(ctx,
		`INSERT INTO wallets (user_id, balance) VALUES ($1, 100)`,
		user.ID,
	)
	if err != nil {
		return nil, fmt.Errorf("create wallet: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	return &user, nil
}

func (s *UserService) Login(ctx context.Context, email, password string) (*models.User, error) {
	var user models.User
	err := s.db.Pool.QueryRow(ctx,
		`SELECT id, username, email, phone, password_hash, status, created_at
		 FROM users WHERE email = $1`,
		email,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Phone, &user.PasswordHash, &user.Status, &user.CreatedAt)

	if err == pgx.ErrNoRows {
		return nil, errors.New("invalid email or password")
	}
	if err != nil {
		return nil, fmt.Errorf("query user: %w", err)
	}

	if user.Status != "active" {
		return nil, errors.New("account is suspended")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, errors.New("invalid email or password")
	}

	return &user, nil
}

func (s *UserService) GenerateTokens(user *models.User, secret string, expiryHours int) (string, string, error) {
	// Access token
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  user.ID,
		"email":    user.Email,
		"username": user.Username,
		"exp":      time.Now().Add(time.Duration(expiryHours) * time.Hour).Unix(),
		"iat":      time.Now().Unix(),
	})

	accessStr, err := accessToken.SignedString([]byte(secret))
	if err != nil {
		return "", "", fmt.Errorf("sign access token: %w", err)
	}

	// Refresh token (longer expiry)
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"type":    "refresh",
		"exp":     time.Now().Add(30 * 24 * time.Hour).Unix(),
		"iat":     time.Now().Unix(),
	})

	refreshStr, err := refreshToken.SignedString([]byte(secret))
	if err != nil {
		return "", "", fmt.Errorf("sign refresh token: %w", err)
	}

	return accessStr, refreshStr, nil
}

func (s *UserService) GetUserByID(ctx context.Context, userID string) (*models.User, error) {
	// Check cache first
	if cached, err := s.rdb.Get("user:" + userID); err == nil {
		var user models.User
		// Parse cached JSON (simplified - in production use proper JSON)
		_ = cached
	}

	var user models.User
	err := s.db.Pool.QueryRow(ctx,
		`SELECT id, username, email, phone, status, created_at FROM users WHERE id = $1`,
		userID,
	).Scan(&user.ID, &user.Username, &user.Email, &user.Phone, &user.Status, &user.CreatedAt)

	if err == pgx.ErrNoRows {
		return nil, errors.New("user not found")
	}
	if err != nil {
		return nil, fmt.Errorf("query user: %w", err)
	}

	return &user, nil
}

func (s *UserService) GetBalance(ctx context.Context, userID string) (*models.BalanceResponse, error) {
	var balance models.BalanceResponse
	err := s.db.Pool.QueryRow(ctx,
		`SELECT balance, currency FROM wallets WHERE user_id = $1`,
		userID,
	).Scan(&balance.Balance, &balance.Currency)

	if err == pgx.ErrNoRows {
		return &models.BalanceResponse{Balance: 0, Currency: "CNY"}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("query balance: %w", err)
	}

	return &balance, nil
}
