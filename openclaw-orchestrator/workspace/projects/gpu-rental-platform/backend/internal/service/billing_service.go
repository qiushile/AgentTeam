package service

import (
	"context"
	"fmt"
	"time"

	"gpucloud/internal/database"
	"gpucloud/internal/models"
)

type BillingService struct {
	db  *database.DB
	rdb *database.Redis
}

func NewBillingService(db *database.DB, rdb *database.Redis) *BillingService {
	return &BillingService{db: db, rdb: rdb}
}

func (s *BillingService) GetBalance(ctx context.Context, userID string) (*models.BalanceResponse, error) {
	var balance models.BalanceResponse
	err := s.db.Pool.QueryRow(ctx,
		`SELECT balance, currency FROM wallets WHERE user_id = $1`,
		userID,
	).Scan(&balance.Balance, &balance.Currency)

	if err != nil {
		return &models.BalanceResponse{Balance: 0, Currency: "CNY"}, nil
	}

	return &balance, nil
}

func (s *BillingService) ListRecords(ctx context.Context, userID string, limit, offset int) ([]models.BillingRecord, error) {
	rows, err := s.db.Pool.Query(ctx,
		`SELECT id, instance_id, user_id, type, amount, status, start_time, end_time, created_at
		 FROM billing_records
		 WHERE user_id = $1
		 ORDER BY created_at DESC
		 LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query billing records: %w", err)
	}
	defer rows.Close()

	var records []models.BillingRecord
	for rows.Next() {
		var r models.BillingRecord
		err := rows.Scan(&r.ID, &r.InstanceID, &r.UserID, &r.Type, &r.Amount,
			&r.Status, &r.StartTime, &r.EndTime, &r.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("scan billing record: %w", err)
		}
		records = append(records, r)
	}

	return records, nil
}

func (s *BillingService) Recharge(ctx context.Context, userID string, req models.RechargeRequest) error {
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Create recharge record
	_, err = tx.Exec(ctx,
		`INSERT INTO recharge_records (user_id, amount, payment_method, status)
		 VALUES ($1, $2, $3, 'completed')`,
		userID, req.Amount, req.PaymentMethod,
	)
	if err != nil {
		return fmt.Errorf("create recharge record: %w", err)
	}

	// Update wallet balance
	_, err = tx.Exec(ctx,
		`UPDATE wallets SET balance = balance + $1, updated_at = NOW() WHERE user_id = $2`,
		req.Amount, userID,
	)
	if err != nil {
		return fmt.Errorf("update balance: %w", err)
	}

	return tx.Commit(ctx)
}

func (s *BillingService) CalculateUsage(ctx context.Context, instanceID, userID string, pricePerHour float64) (float64, error) {
	var startTime time.Time
	err := s.db.Pool.QueryRow(ctx,
		`SELECT started_at FROM gpu_instances WHERE id = $1 AND user_id = $2`,
		instanceID, userID,
	).Scan(&startTime)
	if err != nil {
		return 0, fmt.Errorf("get instance start time: %w", err)
	}

	duration := time.Since(startTime).Hours()
	cost := duration * pricePerHour

	return cost, nil
}

func (s *BillingService) DeductBalance(ctx context.Context, userID string, amount float64) error {
	result, err := s.db.Pool.Exec(ctx,
		`UPDATE wallets SET balance = balance - $1, updated_at = NOW()
		 WHERE user_id = $2 AND balance >= $1`,
		amount, userID,
	)
	if err != nil {
		return fmt.Errorf("deduct balance: %w", err)
	}
	if result.RowsAffected() == 0 {
		return fmt.Errorf("insufficient balance")
	}

	// Create billing record
	_, err = s.db.Pool.Exec(ctx,
		`INSERT INTO billing_records (user_id, type, amount, status)
		 VALUES ($1, 'usage', $2, 'completed')`,
		userID, amount,
	)
	return err
}

func (s *BillingService) GetSummary(ctx context.Context, userID string) (*models.BillingSummary, error) {
	var summary models.BillingSummary

	now := time.Now()
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	lastMonthStart := monthStart.AddDate(0, -1, 0)

	// Total spent
	err := s.db.Pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0) FROM billing_records
		 WHERE user_id = $1 AND type = 'usage' AND status = 'completed'`,
		userID,
	).Scan(&summary.TotalSpent)
	if err != nil {
		return nil, err
	}

	// Current month
	err = s.db.Pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0) FROM billing_records
		 WHERE user_id = $1 AND type = 'usage' AND status = 'completed' AND created_at >= $2`,
		userID, monthStart,
	).Scan(&summary.CurrentMonth)
	if err != nil {
		return nil, err
	}

	// Last month
	err = s.db.Pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(amount), 0) FROM billing_records
		 WHERE user_id = $1 AND type = 'usage' AND status = 'completed'
		 AND created_at >= $2 AND created_at < $3`,
		userID, lastMonthStart, monthStart,
	).Scan(&summary.LastMonth)
	if err != nil {
		return nil, err
	}

	// Running instance count
	err = s.db.Pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM gpu_instances WHERE user_id = $1 AND status = 'running'`,
		userID,
	).Scan(&summary.InstanceCount)
	if err != nil {
		return nil, err
	}

	return &summary, nil
}
