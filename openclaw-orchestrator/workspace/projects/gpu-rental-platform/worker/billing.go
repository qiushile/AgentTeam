package worker

import (
	"context"
	"database/sql"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

// BillingWorker handles periodic billing calculations
type BillingWorker struct {
	DB  *sql.DB
	RDB *redis.Client
}

// NewBillingWorker creates a new billing worker
func NewBillingWorker(db *sql.DB, rdb *redis.Client) *BillingWorker {
	return &BillingWorker{DB: db, RDB: rdb}
}

// Start begins the billing cycle (runs every 5 minutes)
func (w *BillingWorker) Start(ctx context.Context) {
	log.Println("💰 Billing worker started (interval: 5m)")

	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	// Run immediately on start
	w.runBillingCycle(ctx)

	for {
		select {
		case <-ctx.Done():
			log.Println("Billing worker stopped")
			return
		case <-ticker.C:
			w.runBillingCycle(ctx)
		}
	}
}

func (w *BillingWorker) runBillingCycle(ctx context.Context) {
	log.Println("🔄 Running billing cycle...")

	// Find all running instances
	rows, err := w.DB.Query(`
		SELECT id, user_id, hourly_rate 
		FROM gpu_instances 
		WHERE status = 'running'
	`)
	if err != nil {
		log.Printf("❌ Billing query error: %v", err)
		return
	}
	defer rows.Close()

	totalCharged := 0.0
	processed := 0

	for rows.Next() {
		var instanceID, userID int64
		var hourlyRate float64
		if err := rows.Scan(&instanceID, &userID, &hourlyRate); err != nil {
			continue
		}

		// Calculate cost for this cycle (5 min = 1/12 hour)
		cycleHours := 1.0 / 12.0
		cost := hourlyRate * cycleHours

		// Create billing record
		now := time.Now()
		periodStart := now.Add(-5 * time.Minute)
		_, err := w.DB.Exec(`
			INSERT INTO billing_records 
				(user_id, instance_id, period_start, period_end, hours, rate_per_hour, amount, status)
			VALUES ($1, $2, $3, $4, $5, $6, $7, 'charged')
		`, userID, instanceID, periodStart, now, cycleHours, hourlyRate, cost)

		if err != nil {
			log.Printf("❌ Failed to create billing record for instance %d: %v", instanceID, err)
			continue
		}

		// Create usage log
		_, err = w.DB.Exec(`
			INSERT INTO usage_logs (user_id, instance_id, start_time, duration_hours, cost, status)
			VALUES ($1, $2, $3, $4, $5, 'completed')
		`, userID, instanceID, periodStart, cycleHours, cost)

		if err != nil {
			log.Printf("❌ Failed to create usage log for instance %d: %v", instanceID, err)
			continue
		}

		// Deduct from user balance
		_, err = w.DB.Exec("UPDATE users SET balance = balance - $1 WHERE id = $2", cost, userID)
		if err != nil {
			log.Printf("❌ Failed to deduct balance for user %d: %v", userID, err)
			continue
		}

		totalCharged += cost
		processed++
	}

	log.Printf("✅ Billing cycle complete: %d instances processed, ¥%.2f total", processed, totalCharged)

	// Cache summary in Redis
	ctx := context.Background()
	w.RDB.Set(ctx, "billing:last_run", now.Format(time.RFC3339), 24*time.Hour)
	w.RDB.Set(ctx, "billing:instances_processed", processed, 24*time.Hour)
}
