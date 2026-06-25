package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	Pool *pgxpool.Pool
}

func NewPostgres(dsn string) (*DB, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("create connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping database: %w", err)
	}

	return &DB{Pool: pool}, nil
}

func (db *DB) Close() {
	if db.Pool != nil {
		db.Pool.Close()
	}
}

func (db *DB) Migrate() error {
	ctx := context.Background()
	migrations := []string{
		// Users
		`CREATE TABLE IF NOT EXISTS users (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			username VARCHAR(50) UNIQUE NOT NULL,
			email VARCHAR(100) UNIQUE NOT NULL,
			phone VARCHAR(20),
			password_hash VARCHAR(255) NOT NULL,
			status VARCHAR(20) DEFAULT 'active',
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		)`,
		// Wallets
		`CREATE TABLE IF NOT EXISTS wallets (
			user_id UUID PRIMARY KEY REFERENCES users(id),
			balance DECIMAL(10,2) DEFAULT 0,
			currency VARCHAR(3) DEFAULT 'CNY',
			updated_at TIMESTAMP DEFAULT NOW()
		)`,
		// GPU Models
		`CREATE TABLE IF NOT EXISTS gpu_models (
			id SERIAL PRIMARY KEY,
			name VARCHAR(50) UNIQUE NOT NULL,
			vram_gb INT NOT NULL,
			cuda_cores INT,
			mem_bandwidth_gb VARCHAR(20),
			fp32_tflops DECIMAL(6,1),
			price_per_hour DECIMAL(6,2) NOT NULL,
			monthly_price DECIMAL(8,2),
			total_count INT DEFAULT 0,
			available_count INT DEFAULT 0,
			status VARCHAR(20) DEFAULT 'available',
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		// GPU Instances
		`CREATE TABLE IF NOT EXISTS gpu_instances (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID NOT NULL REFERENCES users(id),
			gpu_model_id INT NOT NULL REFERENCES gpu_models(id),
			status VARCHAR(20) DEFAULT 'pending',
			image VARCHAR(100) DEFAULT 'ubuntu-22.04-pytorch',
			ssh_key TEXT,
			ip_address INET,
			container_id VARCHAR(100),
			created_at TIMESTAMP DEFAULT NOW(),
			started_at TIMESTAMP,
			stopped_at TIMESTAMP,
			released_at TIMESTAMP
		)`,
		// Billing Records
		`CREATE TABLE IF NOT EXISTS billing_records (
			id BIGSERIAL PRIMARY KEY,
			instance_id UUID REFERENCES gpu_instances(id),
			user_id UUID NOT NULL REFERENCES users(id),
			type VARCHAR(20) DEFAULT 'usage',
			amount DECIMAL(8,2) NOT NULL,
			status VARCHAR(20) DEFAULT 'pending',
			start_time TIMESTAMP,
			end_time TIMESTAMP,
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		// Recharge Records
		`CREATE TABLE IF NOT EXISTS recharge_records (
			id BIGSERIAL PRIMARY KEY,
			user_id UUID NOT NULL REFERENCES users(id),
			amount DECIMAL(8,2) NOT NULL,
			payment_method VARCHAR(50),
			transaction_id VARCHAR(100),
			status VARCHAR(20) DEFAULT 'completed',
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		// SSH Keys
		`CREATE TABLE IF NOT EXISTS ssh_keys (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID NOT NULL REFERENCES users(id),
			name VARCHAR(100) NOT NULL,
			public_key TEXT NOT NULL,
			fingerprint VARCHAR(100),
			created_at TIMESTAMP DEFAULT NOW()
		)`,
		// API Tokens
		`CREATE TABLE IF NOT EXISTS api_tokens (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			user_id UUID NOT NULL REFERENCES users(id),
			name VARCHAR(100),
			token_hash VARCHAR(255) NOT NULL,
			expires_at TIMESTAMP,
			created_at TIMESTAMP DEFAULT NOW()
		)`,
	}

	for _, sql := range migrations {
		if _, err := db.Pool.Exec(ctx, sql); err != nil {
			return fmt.Errorf("exec migration: %w", err)
		}
	}

	return nil
}
