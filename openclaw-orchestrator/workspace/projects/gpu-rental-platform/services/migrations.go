package services

import (
	"database/sql"
	"log"
)

// RunMigrations creates the database schema
func RunMigrations(db *sql.DB) error {
	log.Println("📦 Running database migrations...")

	migrations := []string{
		// Users table
		`CREATE TABLE IF NOT EXISTS users (
			id BIGSERIAL PRIMARY KEY,
			username VARCHAR(32) UNIQUE NOT NULL,
			email VARCHAR(128) UNIQUE NOT NULL,
			password_hash VARCHAR(256) NOT NULL,
			balance DECIMAL(10,2) DEFAULT 0,
			status VARCHAR(16) DEFAULT 'active',
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		)`,

		// GPU Instances table
		`CREATE TABLE IF NOT EXISTS gpu_instances (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			name VARCHAR(64) NOT NULL,
			gpu_type VARCHAR(32) NOT NULL,
			memory_gb INT NOT NULL,
			vcpus INT NOT NULL,
			status VARCHAR(16) DEFAULT 'creating',
			public_ip VARCHAR(45),
			ssh_port INT,
			hourly_rate DECIMAL(10,2) NOT NULL,
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		)`,

		// Orders table
		`CREATE TABLE IF NOT EXISTS orders (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			amount DECIMAL(10,2) NOT NULL,
			status VARCHAR(16) DEFAULT 'pending',
			pay_method VARCHAR(32),
			pay_id VARCHAR(128),
			description TEXT,
			created_at TIMESTAMP DEFAULT NOW(),
			paid_at TIMESTAMP
		)`,

		// Usage logs table
		`CREATE TABLE IF NOT EXISTS usage_logs (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			instance_id BIGINT REFERENCES gpu_instances(id),
			start_time TIMESTAMP NOT NULL,
			end_time TIMESTAMP,
			duration_hours DECIMAL(10,2) DEFAULT 0,
			cost DECIMAL(10,2) DEFAULT 0,
			status VARCHAR(16) DEFAULT 'active'
		)`,

		// API Keys table
		`CREATE TABLE IF NOT EXISTS api_keys (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			key VARCHAR(128) UNIQUE NOT NULL,
			name VARCHAR(64),
			last_used TIMESTAMP,
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMP DEFAULT NOW()
		)`,

		// System logs table
		`CREATE TABLE IF NOT EXISTS system_logs (
			id BIGSERIAL PRIMARY KEY,
			level VARCHAR(16) DEFAULT 'info',
			service VARCHAR(64),
			message TEXT,
			metadata JSONB,
			created_at TIMESTAMP DEFAULT NOW()
		)`,

		// Notifications table
		`CREATE TABLE IF NOT EXISTS notifications (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			title VARCHAR(128),
			content TEXT,
			type VARCHAR(32) DEFAULT 'system',
			is_read BOOLEAN DEFAULT false,
			created_at TIMESTAMP DEFAULT NOW()
		)`,

		// Billing records table
		`CREATE TABLE IF NOT EXISTS billing_records (
			id BIGSERIAL PRIMARY KEY,
			user_id BIGINT REFERENCES users(id),
			instance_id BIGINT REFERENCES gpu_instances(id),
			period_start TIMESTAMP NOT NULL,
			period_end TIMESTAMP NOT NULL,
			hours DECIMAL(10,2) NOT NULL,
			rate_per_hour DECIMAL(10,2) NOT NULL,
			amount DECIMAL(10,2) NOT NULL,
			status VARCHAR(16) DEFAULT 'pending',
			created_at TIMESTAMP DEFAULT NOW()
		)`,

		// Indexes
		`CREATE INDEX IF NOT EXISTS idx_gpu_instances_user ON gpu_instances(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_gpu_instances_status ON gpu_instances(status)`,
		`CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_usage_logs_user ON usage_logs(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_api_keys_user ON api_keys(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read)`,
		`CREATE INDEX IF NOT EXISTS idx_billing_records_user ON billing_records(user_id)`,
	}

	for i, query := range migrations {
		if _, err := db.Exec(query); err != nil {
			return err
		}
		log.Printf("  ✅ Migration %d applied", i+1)
	}

	log.Println("✅ All migrations applied successfully")
	return nil
}
