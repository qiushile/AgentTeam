package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"gpucloud/internal/database"
	"gpucloud/internal/models"

	"github.com/jackc/pgx/v5"
)

type InstanceService struct {
	db      *database.DB
	rdb     *database.Redis
	gpuSvc  *GPUService
}

func NewInstanceService(db *database.DB, rdb *database.Redis, gpuSvc *GPUService) *InstanceService {
	return &InstanceService{db: db, rdb: rdb, gpuSvc: gpuSvc}
}

func (s *InstanceService) Create(ctx context.Context, userID string, req models.CreateInstanceRequest) (*models.Instance, error) {
	// Check GPU availability
	available, err := s.gpuSvc.CheckAvailability(ctx, req.GPUModelID)
	if err != nil {
		return nil, err
	}
	if !available {
		return nil, errors.New("GPU model currently unavailable")
	}

	// Check user balance
	var balance float64
	err = s.db.Pool.QueryRow(ctx, `SELECT balance FROM wallets WHERE user_id = $1`, userID).Scan(&balance)
	if err != nil {
		return nil, fmt.Errorf("check balance: %w", err)
	}

	// Get GPU price
	var pricePerHour float64
	err = s.db.Pool.QueryRow(ctx, `SELECT price_per_hour FROM gpu_models WHERE id = $1`, req.GPUModelID).Scan(&pricePerHour)
	if err != nil {
		return nil, fmt.Errorf("get gpu price: %w", err)
	}

	// Require minimum balance (2 hours)
	if balance < pricePerHour*2 {
		return nil, errors.New("insufficient balance, minimum 2 hours required")
	}

	// Begin transaction
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Decrement GPU availability
	_, err = tx.Exec(ctx, `UPDATE gpu_models SET available_count = available_count - 1 WHERE id = $1`, req.GPUModelID)
	if err != nil {
		return nil, fmt.Errorf("decrement gpu: %w", err)
	}

	// Create instance
	image := "ubuntu-22.04-pytorch"
	if req.Image != "" {
		image = req.Image
	}

	var instance models.Instance
	err = tx.QueryRow(ctx,
		`INSERT INTO gpu_instances (user_id, gpu_model_id, image, status)
		 VALUES ($1, $2, $3, 'pending')
		 RETURNING id, user_id, gpu_model_id, status, image, created_at`,
		userID, req.GPUModelID, image,
	).Scan(&instance.ID, &instance.UserID, &instance.GPUModelID, &instance.Status,
		&instance.Image, &instance.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("create instance: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit tx: %w", err)
	}

	// Async: trigger Kubernetes pod creation (would use message queue in production)
	go s.provisionInstance(instance.ID, req.GPUModelID)

	return &instance, nil
}

func (s *InstanceService) provisionInstance(instanceID string, gpuModelID int) {
	// In production: call Kubernetes API to create GPU pod
	// Simulate provisioning delay
	time.Sleep(3 * time.Second)

	ctx := context.Background()
	// Update status to running
	_, err := s.db.Pool.Exec(ctx,
		`UPDATE gpu_instances SET status = 'running', started_at = NOW(),
		        ip_address = $1, container_id = $2
		 WHERE id = $3`,
		fmt.Sprintf("10.0.%d.%d", gpuModelID/10, gpuModelID%10+10),
		fmt.Sprintf("gpu-pod-%s", instanceID[:8]),
		instanceID,
	)
	if err != nil {
		// Log error in production
		_ = err
	}
}

func (s *InstanceService) ListByUser(ctx context.Context, userID string, limit, offset int) ([]models.Instance, error) {
	rows, err := s.db.Pool.Query(ctx,
		`SELECT i.id, i.user_id, i.gpu_model_id, i.status, i.image, i.ip_address::text,
		        i.container_id, i.created_at, i.started_at, i.stopped_at,
		        g.name, g.vram_gb, g.price_per_hour
		 FROM gpu_instances i
		 JOIN gpu_models g ON i.gpu_model_id = g.id
		 WHERE i.user_id = $1 AND i.status != 'terminated'
		 ORDER BY i.created_at DESC
		 LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	if err != nil {
		return nil, fmt.Errorf("query instances: %w", err)
	}
	defer rows.Close()

	var instances []models.Instance
	for rows.Next() {
		var inst models.Instance
		var ip, containerID *string
		var startedAt, stoppedAt *time.Time
		err := rows.Scan(&inst.ID, &inst.UserID, &inst.GPUModelID, &inst.Status, &inst.Image,
			&ip, &containerID, &inst.CreatedAt, &startedAt, &stoppedAt,
			&inst.GPUModel.Name, &inst.GPUModel.VRAMGB, &inst.GPUModel.PricePerHour)
		if err != nil {
			return nil, fmt.Errorf("scan instance: %w", err)
		}
		if ip != nil {
			inst.IPAddress = *ip
		}
		if containerID != nil {
			inst.ContainerID = *containerID
		}
		inst.StartedAt = startedAt
		inst.StoppedAt = stoppedAt
		instances = append(instances, inst)
	}

	return instances, nil
}

func (s *InstanceService) GetByID(ctx context.Context, userID, instanceID string) (*models.Instance, error) {
	var inst models.Instance
	err := s.db.Pool.QueryRow(ctx,
		`SELECT i.id, i.user_id, i.gpu_model_id, i.status, i.image, i.ip_address::text,
		        i.container_id, i.created_at, i.started_at, i.stopped_at,
		        g.name, g.vram_gb, g.price_per_hour
		 FROM gpu_instances i
		 JOIN gpu_models g ON i.gpu_model_id = g.id
		 WHERE i.id = $1 AND i.user_id = $2`,
		instanceID, userID,
	).Scan(&inst.ID, &inst.UserID, &inst.GPUModelID, &inst.Status, &inst.Image,
		&inst.IPAddress, &inst.ContainerID, &inst.CreatedAt, &inst.StartedAt, &inst.StoppedAt,
		&inst.GPUModel.Name, &inst.GPUModel.VRAMGB, &inst.GPUModel.PricePerHour)

	if err == pgx.ErrNoRows {
		return nil, errors.New("instance not found")
	}
	if err != nil {
		return nil, fmt.Errorf("query instance: %w", err)
	}

	return &inst, nil
}

func (s *InstanceService) Start(ctx context.Context, userID, instanceID string) error {
	result, err := s.db.Pool.Exec(ctx,
		`UPDATE gpu_instances SET status = 'pending', started_at = NOW()
		 WHERE id = $1 AND user_id = $2 AND status = 'stopped'`,
		instanceID, userID,
	)
	if err != nil {
		return fmt.Errorf("start instance: %w", err)
	}
	if result.RowsAffected() == 0 {
		return errors.New("instance not found or not in stopped state")
	}
	return nil
}

func (s *InstanceService) Stop(ctx context.Context, userID, instanceID string) error {
	result, err := s.db.Pool.Exec(ctx,
		`UPDATE gpu_instances SET status = 'stopped', stopped_at = NOW()
		 WHERE id = $1 AND user_id = $2 AND status = 'running'`,
		instanceID, userID,
	)
	if err != nil {
		return fmt.Errorf("stop instance: %w", err)
	}
	if result.RowsAffected() == 0 {
		return errors.New("instance not found or not running")
	}
	return nil
}

func (s *InstanceService) Release(ctx context.Context, userID, instanceID string) error {
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	// Get instance GPU model
	var gpuModelID int
	err = tx.QueryRow(ctx,
		`SELECT gpu_model_id FROM gpu_instances WHERE id = $1 AND user_id = $2 AND status != 'terminated'`,
		instanceID, userID,
	).Scan(&gpuModelID)
	if err != nil {
		return errors.New("instance not found or already terminated")
	}

	// Release GPU back to pool
	_, err = tx.Exec(ctx, `UPDATE gpu_models SET available_count = available_count + 1 WHERE id = $1`, gpuModelID)
	if err != nil {
		return fmt.Errorf("release gpu: %w", err)
	}

	// Mark instance as terminated
	_, err = tx.Exec(ctx,
		`UPDATE gpu_instances SET status = 'terminated', released_at = NOW() WHERE id = $1`,
		instanceID,
	)
	if err != nil {
		return fmt.Errorf("terminate instance: %w", err)
	}

	return tx.Commit(ctx)
}

func (s *InstanceService) GetSSHInfo(ctx context.Context, userID, instanceID string) (*models.SSHInfo, error) {
	var ip string
	var status string
	err := s.db.Pool.QueryRow(ctx,
		`SELECT ip_address::text, status FROM gpu_instances WHERE id = $1 AND user_id = $2`,
		instanceID, userID,
	).Scan(&ip, &status)
	if err != nil {
		return nil, errors.New("instance not found")
	}
	if status != "running" {
		return nil, errors.New("instance is not running")
	}

	return &models.SSHInfo{
		Host:         ip,
		Port:         22,
		User:         "root",
		SSHPort:      22,
		JupyterURL:   fmt.Sprintf("http://%s:8888", ip),
	}, nil
}
