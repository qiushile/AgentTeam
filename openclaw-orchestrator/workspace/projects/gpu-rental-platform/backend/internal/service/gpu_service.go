package service

import (
	"context"
	"errors"
	"fmt"

	"gpucloud/internal/database"
	"gpucloud/internal/models"

	"github.com/jackc/pgx/v5"
)

type GPUService struct {
	db *database.DB
}

func NewGPUService(db *database.DB) *GPUService {
	return &GPUService{db: db}
}

func (s *GPUService) ListModels(ctx context.Context) ([]models.GPUModel, error) {
	rows, err := s.db.Pool.Query(ctx,
		`SELECT id, name, vram_gb, cuda_cores, mem_bandwidth_gb, fp32_tflops,
		        price_per_hour, monthly_price, total_count, available_count, status
		 FROM gpu_models WHERE status = 'available' ORDER BY price_per_hour ASC`,
	)
	if err != nil {
		return nil, fmt.Errorf("query gpu models: %w", err)
	}
	defer rows.Close()

	var models_list []models.GPUModel
	for rows.Next() {
		var g models.GPUModel
		err := rows.Scan(&g.ID, &g.Name, &g.VRAMGB, &g.CUDACores, &g.MemBandwidthGB,
			&g.FP32TFlops, &g.PricePerHour, &g.MonthlyPrice, &g.TotalCount,
			&g.AvailableCount, &g.Status)
		if err != nil {
			return nil, fmt.Errorf("scan gpu model: %w", err)
		}
		models_list = append(models_list, g)
	}

	return models_list, nil
}

func (s *GPUService) GetModel(ctx context.Context, id int) (*models.GPUModel, error) {
	var g models.GPUModel
	err := s.db.Pool.QueryRow(ctx,
		`SELECT id, name, vram_gb, cuda_cores, mem_bandwidth_gb, fp32_tflops,
		        price_per_hour, monthly_price, total_count, available_count, status
		 FROM gpu_models WHERE id = $1`,
		id,
	).Scan(&g.ID, &g.Name, &g.VRAMGB, &g.CUDACores, &g.MemBandwidthGB,
		&g.FP32TFlops, &g.PricePerHour, &g.MonthlyPrice, &g.TotalCount,
		&g.AvailableCount, &g.Status)

	if err == pgx.ErrNoRows {
		return nil, errors.New("gpu model not found")
	}
	if err != nil {
		return nil, fmt.Errorf("query gpu model: %w", err)
	}

	return &g, nil
}

func (s *GPUService) CheckAvailability(ctx context.Context, gpuModelID int) (bool, error) {
	var available int
	err := s.db.Pool.QueryRow(ctx,
		`SELECT available_count FROM gpu_models WHERE id = $1`,
		gpuModelID,
	).Scan(&available)

	if err != nil {
		return false, fmt.Errorf("check availability: %w", err)
	}

	return available > 0, nil
}

func (s *GPUService) DecrementAvailability(ctx context.Context, gpuModelID int) error {
	result, err := s.db.Pool.Exec(ctx,
		`UPDATE gpu_models SET available_count = available_count - 1
		 WHERE id = $1 AND available_count > 0`,
		gpuModelID,
	)
	if err != nil {
		return fmt.Errorf("decrement availability: %w", err)
	}

	if result.RowsAffected() == 0 {
		return errors.New("gpu model out of stock")
	}

	return nil
}

func (s *GPUService) IncrementAvailability(ctx context.Context, gpuModelID int) error {
	_, err := s.db.Pool.Exec(ctx,
		`UPDATE gpu_models SET available_count = available_count + 1 WHERE id = $1`,
		gpuModelID,
	)
	return err
}

// Seed initial GPU models
func (s *GPUService) SeedModels(ctx context.Context) error {
	models := []struct {
		Name       string
		VRAM       int
		Cores      int
		Bandwidth  string
		TFlops     float64
		Hourly     float64
		Monthly    float64
		Total      int
		Available  int
	}{
		{"RTX 4080", 16, 9728, "717 GB/s", 48.7, 1.50, 756, 100, 100},
		{"RTX 4090", 24, 16384, "1008 GB/s", 82.6, 2.50, 1260, 200, 200},
		{"V100 32G", 32, 5120, "900 GB/s", 15.7, 2.00, 1008, 50, 48},
		{"A100 40G", 40, 6912, "1555 GB/s", 19.5, 5.00, 2520, 150, 150},
		{"A100 80G", 80, 6912, "2039 GB/s", 19.5, 8.00, 4032, 100, 100},
		{"H100 80G", 80, 16896, "3350 GB/s", 67.0, 18.00, 9072, 30, 28},
	}

	for _, m := range models {
		var exists bool
		err := s.db.Pool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM gpu_models WHERE name = $1)", m.Name).Scan(&exists)
		if err != nil {
			return err
		}
		if !exists {
			_, err = s.db.Pool.Exec(ctx,
				`INSERT INTO gpu_models (name, vram_gb, cuda_cores, mem_bandwidth_gb, fp32_tflops,
				                        price_per_hour, monthly_price, total_count, available_count)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
				m.Name, m.VRAM, m.Cores, m.Bandwidth, m.TFlops,
				m.Hourly, m.Monthly, m.Total, m.Available,
			)
			if err != nil {
				return fmt.Errorf("seed model %s: %w", m.Name, err)
			}
		}
	}

	return nil
}
