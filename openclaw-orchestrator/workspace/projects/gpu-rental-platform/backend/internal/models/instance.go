package models

import "time"

type GPUModel struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	VRAMGB           int       `json:"vram_gb"`
	CUDACores        int       `json:"cuda_cores"`
	MemBandwidthGB   string    `json:"mem_bandwidth_gb"`
	FP32TFlops       float64   `json:"fp32_tflops"`
	PricePerHour     float64   `json:"price_per_hour"`
	MonthlyPrice     float64   `json:"monthly_price"`
	TotalCount       int       `json:"total_count"`
	AvailableCount   int       `json:"available_count"`
	Status           string    `json:"status"`
	CreatedAt        time.Time `json:"created_at"`
}

type CreateInstanceRequest struct {
	GPUModelID int    `json:"gpu_model_id" binding:"required"`
	Image      string `json:"image"`
	SSHKeyID   string `json:"ssh_key_id"`
}

type Instance struct {
	ID          string     `json:"id"`
	UserID      string     `json:"user_id"`
	GPUModelID  int        `json:"gpu_model_id"`
	GPUModel    GPUModel   `json:"gpu_model"`
	Status      string     `json:"status"`
	Image       string     `json:"image"`
	SSHKey      string     `json:"ssh_key,omitempty"`
	IPAddress   string     `json:"ip_address,omitempty"`
	ContainerID string     `json:"container_id,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	StartedAt   *time.Time `json:"started_at,omitempty"`
	StoppedAt   *time.Time `json:"stopped_at,omitempty"`
}

type SSHInfo struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	User     string `json:"user"`
	SSHPort  int    `json:"ssh_port"`
	JupyterURL string `json:"jupyter_url"`
}

type InstanceStatus string

const (
	StatusPending   InstanceStatus = "pending"
	StatusRunning   InstanceStatus = "running"
	StatusStopped   InstanceStatus = "stopped"
	StatusTerminated InstanceStatus = "terminated"
	StatusError     InstanceStatus = "error"
)
