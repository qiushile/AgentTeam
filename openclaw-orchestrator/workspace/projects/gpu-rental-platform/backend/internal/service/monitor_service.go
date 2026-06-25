package service

import (
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"time"

	"gpucloud/internal/database"
)

type MonitorService struct {
	rdb *database.Redis
}

func NewMonitorService(rdb *database.Redis) *MonitorService {
	return &MonitorService{rdb: rdb}
}

type GPUMetrics struct {
	GPUUtilization float64   `json:"gpu_utilization"`
	MemoryUsed     float64   `json:"memory_used_gb"`
	MemoryTotal    float64   `json:"memory_total_gb"`
	Temperature    float64   `json:"temperature_c"`
	PowerUsage     float64   `json:"power_usage_w"`
	NetworkIn      float64   `json:"network_in_mbps"`
	NetworkOut     float64   `json:"network_out_mbps"`
	DiskIORead     float64   `json:"disk_io_read_mbps"`
	DiskIOWrite    float64   `json:"disk_io_write_mbps"`
	Timestamp      time.Time `json:"timestamp"`
}

func (s *MonitorService) GetMetrics(ctx context.Context, instanceID string) (*GPUMetrics, error) {
	// Try cache first
	if data, err := s.rdb.Get("metrics:" + instanceID); err == nil {
		var metrics GPUMetrics
		if err := json.Unmarshal([]byte(data), &metrics); err == nil {
			return &metrics, nil
		}
	}

	// In production: query Prometheus or kube-state-metrics
	// For now: simulate metrics
	metrics := s.simulateMetrics()

	// Cache for 30 seconds
	if data, err := json.Marshal(metrics); err == nil {
		_ = s.rdb.Set("metrics:"+instanceID, string(data), 30*time.Second)
	}

	return metrics, nil
}

func (s *MonitorService) GetMetricsHistory(ctx context.Context, instanceID string, hours int) ([]GPUMetrics, error) {
	// In production: query Prometheus range query
	// Simulate historical data
	var history []GPUMetrics
	now := time.Now()
	for i := hours; i >= 0; i-- {
		m := s.simulateMetrics()
		m.Timestamp = now.Add(time.Duration(-i) * time.Hour)
		history = append(history, *m)
	}
	return history, nil
}

func (s *MonitorService) simulateMetrics() *GPUMetrics {
	return &GPUMetrics{
		GPUUtilization: 45 + rand.Float64()*40,
		MemoryUsed:     12 + rand.Float64()*20,
		MemoryTotal:    80,
		Temperature:    55 + rand.Float64()*25,
		PowerUsage:     200 + rand.Float64()*200,
		NetworkIn:      rand.Float64() * 100,
		NetworkOut:     rand.Float64() * 50,
		DiskIORead:     rand.Float64() * 500,
		DiskIOWrite:    rand.Float64() * 200,
		Timestamp:      time.Now(),
	}
}

func (s *MonitorService) PushMetrics(instanceID string, metrics *GPUMetrics) error {
	data, err := json.Marshal(metrics)
	if err != nil {
		return fmt.Errorf("marshal metrics: %w", err)
	}
	return s.rdb.Set("metrics:"+instanceID, string(data), 30*time.Second)
}
