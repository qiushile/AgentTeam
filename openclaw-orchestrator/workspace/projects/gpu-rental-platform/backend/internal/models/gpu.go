package models

import "time"

type GPUModel struct {
	ID             int       `json:"id"`
	Name           string    `json:"name"`
	VRAMGB         int       `json:"vram_gb"`
	CUDACores      int       `json:"cuda_cores"`
	MemBandwidthGB string    `json:"mem_bandwidth_gb"`
	FP32TFlops     float64   `json:"fp32_tflops"`
	PricePerHour   float64   `json:"price_per_hour"`
	MonthlyPrice   float64   `json:"monthly_price"`
	TotalCount     int       `json:"total_count"`
	AvailableCount int       `json:"available_count"`
	Status         string    `json:"status"`
	CreatedAt      time.Time `json:"created_at"`
}
