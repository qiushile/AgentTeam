package model

import "time"

// User 用户表
type User struct {
	ID           int64     `json:"id"`
	Username     string    `json:"username"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	Balance      float64   `json:"balance"`
	Status       string    `json:"status"` // active, suspended
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// GPUInstance GPU 实例表
type GPUInstance struct {
	ID          int64     `json:"id"`
	UserID      int64     `json:"user_id"`
	Name        string    `json:"name"`
	GPUType     string    `json:"gpu_type"` // A100, V100, RTX4090
	MemoryGB    int       `json:"memory_gb"`
	VCPUs       int       `json:"vcpus"`
	Status      string    `json:"status"` // running, stopped, creating, error
	PublicIP    string    `json:"public_ip,omitempty"`
	SSHPort     int       `json:"ssh_port,omitempty"`
	HourlyRate  float64   `json:"hourly_rate"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Order 订单表
type Order struct {
	ID          int64     `json:"id"`
	UserID      int64     `json:"user_id"`
	Amount      float64   `json:"amount"`
	Status      string    `json:"status"` // pending, paid, cancelled, refunded
	PayMethod   string    `json:"pay_method"`
	PayID       string    `json:"pay_id,omitempty"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	PaidAt      time.Time `json:"paid_at,omitempty"`
}

// UsageLog 使用记录表
type UsageLog struct {
	ID         int64     `json:"id"`
	UserID     int64     `json:"user_id"`
	InstanceID int64     `json:"instance_id"`
	StartTime  time.Time `json:"start_time"`
	EndTime    time.Time `json:"end_time,omitempty"`
	DurationH  float64   `json:"duration_hours"`
	Cost       float64   `json:"cost"`
	Status     string    `json:"status"` // active, completed
}

// APIKey API 密钥表
type APIKey struct {
	ID        int64     `json:"id"`
	UserID    int64     `json:"user_id"`
	Key       string    `json:"key"`
	Name      string    `json:"name"`
	LastUsed  time.Time `json:"last_used,omitempty"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

// SystemLog 系统日志表
type SystemLog struct {
	ID        int64     `json:"id"`
	Level     string    `json:"level"` // info, warn, error
	Service   string    `json:"service"`
	Message   string    `json:"message"`
	Metadata  string    `json:"metadata,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// Notification 通知表
type Notification struct {
	ID        int64     `json:"id"`
	UserID    int64     `json:"user_id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	Type      string    `json:"type"` // system, billing, alert
	IsRead    bool      `json:"is_read"`
	CreatedAt time.Time `json:"created_at"`
}

// BillingRecord 计费记录表
type BillingRecord struct {
	ID          int64     `json:"id"`
	UserID      int64     `json:"user_id"`
	InstanceID  int64     `json:"instance_id"`
	PeriodStart time.Time `json:"period_start"`
	PeriodEnd   time.Time `json:"period_end"`
	Hours       float64   `json:"hours"`
	RatePerHour float64   `json:"rate_per_hour"`
	Amount      float64   `json:"amount"`
	Status      string    `json:"status"` // pending, charged, failed
	CreatedAt   time.Time `json:"created_at"`
}
