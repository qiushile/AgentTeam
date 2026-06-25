package models

import "time"

type BillingRecord struct {
	ID         int64      `json:"id"`
	InstanceID string     `json:"instance_id"`
	UserID     string     `json:"user_id"`
	Type       string     `json:"type"` // usage, recharge, refund
	Amount     float64    `json:"amount"`
	Status     string     `json:"status"` // pending, completed, failed
	StartTime  *time.Time `json:"start_time,omitempty"`
	EndTime    *time.Time `json:"end_time,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

type RechargeRequest struct {
	Amount        float64 `json:"amount" binding:"required,gt=0"`
	PaymentMethod string  `json:"payment_method" binding:"required"`
}

type BalanceResponse struct {
	Balance  float64 `json:"balance"`
	Currency string  `json:"currency"`
}

type BillingSummary struct {
	TotalSpent    float64 `json:"total_spent"`
	CurrentMonth  float64 `json:"current_month"`
	LastMonth     float64 `json:"last_month"`
	InstanceCount int     `json:"instance_count"`
}
