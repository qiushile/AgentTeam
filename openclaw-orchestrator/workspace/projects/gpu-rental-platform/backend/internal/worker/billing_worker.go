package worker

import (
	"context"
	"log"
	"time"

	"gpucloud/internal/database"
)

// BillingWorker 按小时扣费定时任务
type BillingWorker struct {
	db  *database.DB
	rdb *database.Redis
}

func NewBillingWorker(db *database.DB, rdb *database.Redis) *BillingWorker {
	return &BillingWorker{db: db, rdb: rdb}
}

// Start 启动计费轮询（每小时执行一次）
func (w *BillingWorker) Start(ctx context.Context, interval time.Duration) {
	log.Printf("[BillingWorker] Started, interval: %v", interval)

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("[BillingWorker] Stopped")
			return
		case <-ticker.C:
			w.processBillingCycle(ctx)
		}
	}
}

func (w *BillingWorker) processBillingCycle(ctx context.Context) {
	log.Println("[BillingWorker] Processing billing cycle...")

	// 1. 查询所有运行中且已启动的实例
	rows, err := w.db.Pool.Query(ctx,
		`SELECT i.id, i.user_id, i.started_at, i.gpu_model_id, g.price_per_hour
		 FROM gpu_instances i
		 JOIN gpu_models g ON i.gpu_model_id = g.id
		 WHERE i.status = 'running' AND i.started_at IS NOT NULL`,
	)
	if err != nil {
		log.Printf("[BillingWorker] Query running instances failed: %v", err)
		return
	}
	defer rows.Close()

	var processed, failed, stopped int

	for rows.Next() {
		var instanceID, userID string
		var startedAt time.Time
		var gpuModelID int
		var pricePerHour float64

		if err := rows.Scan(&instanceID, &userID, &startedAt, &gpuModelID, &pricePerHour); err != nil {
			log.Printf("[BillingWorker] Scan failed: %v", err)
			continue
		}

		// 计算从上次计费到现在的时长
		var lastBilledAt time.Time
		err := w.db.Pool.QueryRow(ctx,
			`SELECT COALESCE(MAX(end_time), $1) FROM billing_records
			 WHERE instance_id = $2 AND type = 'usage'`,
			startedAt, instanceID,
		).Scan(&lastBilledAt)
		if err != nil {
			lastBilledAt = startedAt
		}

		duration := time.Since(lastBilledAt).Hours()
		if duration <= 0 {
			continue
		}

		cost := duration * pricePerHour

		// 检查余额
		var balance float64
		err = w.db.Pool.QueryRow(ctx,
			`SELECT balance FROM wallets WHERE user_id = $1`,
			userID,
		).Scan(&balance)
		if err != nil {
			failed++
			continue
		}

		if balance < cost {
			// 余额不足，停止实例
			_, err = w.db.Pool.Exec(ctx,
				`UPDATE gpu_instances SET status = 'stopped', stopped_at = NOW() WHERE id = $1`,
				instanceID,
			)
			if err != nil {
				log.Printf("[BillingWorker] Stop instance %s failed: %v", instanceID, err)
			} else {
				log.Printf("[BillingWorker] Instance %s stopped due to insufficient balance", instanceID)
				stopped++
			}

			// 结算最后一段费用
			finalCost := balance
			if finalCost > 0 {
				_, _ = w.db.Pool.Exec(ctx,
					`INSERT INTO billing_records (instance_id, user_id, type, amount, status, start_time, end_time)
					 VALUES ($1, $2, 'usage', $3, 'completed', $4, NOW())`,
					instanceID, userID, finalCost, lastBilledAt,
				)
				_, _ = w.db.Pool.Exec(ctx,
					`UPDATE wallets SET balance = 0, updated_at = NOW() WHERE user_id = $1`,
					userID,
				)
			}
			continue
		}

		// 扣费
		tx, err := w.db.Pool.Begin(ctx)
		if err != nil {
			failed++
			continue
		}

		_, err = tx.Exec(ctx,
			`UPDATE wallets SET balance = balance - $1, updated_at = NOW() WHERE user_id = $2`,
			cost, userID,
		)
		if err != nil {
			tx.Rollback(ctx)
			failed++
			continue
		}

		_, err = tx.Exec(ctx,
			`INSERT INTO billing_records (instance_id, user_id, type, amount, status, start_time, end_time)
			 VALUES ($1, $2, 'usage', $3, 'completed', $4, NOW())`,
			instanceID, userID, cost, lastBilledAt,
		)
		if err != nil {
			tx.Rollback(ctx)
			failed++
			continue
		}

		if err := tx.Commit(ctx); err != nil {
			failed++
			continue
		}

		processed++
	}

	log.Printf("[BillingWorker] Cycle complete: processed=%d, failed=%d, stopped=%d",
		processed, failed, stopped)
}
