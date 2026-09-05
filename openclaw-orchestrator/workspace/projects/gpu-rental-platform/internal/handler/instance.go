package handler

import (
	"database/sql"
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type InstanceHandler struct {
	DB *sql.DB
}

// GPU price per hour by type
var gpuPrices = map[string]float64{
	"rtx4090": 1.50,
	"v100":    3.00,
	"a100_40": 8.00,
	"a100_80": 15.00,
	"h100":    25.00,
}

func NewInstanceHandler(db *sql.DB) *InstanceHandler {
	return &InstanceHandler{DB: db}
}

// CreateInstance creates a new GPU instance
func (h *InstanceHandler) CreateInstance(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req struct {
		Name    string `json:"name" binding:"required"`
		GPUType string `json:"gpu_type" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	price, ok := gpuPrices[req.GPUType]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "unsupported GPU type"})
		return
	}

	// Check user balance
	var balance float64
	err := h.DB.QueryRow("SELECT balance FROM users WHERE id = $1", userID).Scan(&balance)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	if balance < price {
		c.JSON(http.StatusBadRequest, gin.H{"error": "insufficient balance"})
		return
	}

	var instanceID int64
	err = h.DB.QueryRow(`
		INSERT INTO gpu_instances (user_id, name, gpu_type, status, hourly_rate, memory_gb, vcpus)
		VALUES ($1, $2, $3, 'creating', $4, 
			CASE WHEN $3 = 'a100_80' THEN 80 WHEN $3 = 'a100_40' THEN 40 
				WHEN $3 = 'v100' THEN 32 WHEN $3 = 'h100' THEN 80 ELSE 24 END,
			CASE WHEN $3 = 'h100' THEN 16 ELSE 8 END)
		RETURNING id
	`, userID, req.Name, req.GPUType, price).Scan(&instanceID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create instance"})
		return
	}

	// Simulate IP assignment
	ip := fmt.Sprintf("10.0.%d.%d", rand.Intn(256), rand.Intn(256))
	_, _ = h.DB.Exec("UPDATE gpu_instances SET status = 'running', public_ip = $1, ssh_port = $2 WHERE id = $3",
		ip, 22000+int(instanceID), instanceID)

	c.JSON(http.StatusCreated, gin.H{
		"instance_id": instanceID,
		"status":      "running",
		"gpu_type":    req.GPUType,
		"hourly_rate": price,
		"public_ip":   ip,
	})
}

// ListInstances returns all instances for the current user
func (h *InstanceHandler) ListInstances(c *gin.Context) {
	userID := c.GetInt64("user_id")

	rows, err := h.DB.Query(`
		SELECT id, name, gpu_type, memory_gb, vcpus, status, public_ip, ssh_port, hourly_rate, created_at
		FROM gpu_instances WHERE user_id = $1 ORDER BY created_at DESC
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var instances []gin.H
	for rows.Next() {
		var inst struct {
			ID         int64     `json:"id"`
			Name       string    `json:"name"`
			GPUType    string    `json:"gpu_type"`
			MemoryGB   int       `json:"memory_gb"`
			VCPUs      int       `json:"vcpus"`
			Status     string    `json:"status"`
			PublicIP   *string   `json:"public_ip"`
			SSHPort    *int      `json:"ssh_port"`
			HourlyRate float64   `json:"hourly_rate"`
			CreatedAt  time.Time `json:"created_at"`
		}
		if err := rows.Scan(&inst.ID, &inst.Name, &inst.GPUType, &inst.MemoryGB,
			&inst.VCPUs, &inst.Status, &inst.PublicIP, &inst.SSHPort, &inst.HourlyRate, &inst.CreatedAt); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "scan error"})
			return
		}
		instances = append(instances, gin.H{
			"id":           inst.ID,
			"name":         inst.Name,
			"gpu_type":     inst.GPUType,
			"memory_gb":    inst.MemoryGB,
			"vcpus":        inst.VCPUs,
			"status":       inst.Status,
			"public_ip":    inst.PublicIP,
			"ssh_port":     inst.SSHPort,
			"hourly_rate":  inst.HourlyRate,
			"created_at":   inst.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"instances": instances})
}

// StopInstance stops a running instance
func (h *InstanceHandler) StopInstance(c *gin.Context) {
	userID := c.GetInt64("user_id")
	instanceID := c.Param("id")

	result, err := h.DB.Exec(
		"UPDATE gpu_instances SET status = 'stopped' WHERE id = $1 AND user_id = $2",
		instanceID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "instance not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "instance stopped"})
}

// DeleteInstance deletes a stopped instance
func (h *InstanceHandler) DeleteInstance(c *gin.Context) {
	userID := c.GetInt64("user_id")
	instanceID := c.Param("id")

	result, err := h.DB.Exec(
		"DELETE FROM gpu_instances WHERE id = $1 AND user_id = $2 AND status = 'stopped'",
		instanceID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "instance not found or not stopped"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "instance deleted"})
}

// GetGPUPrices returns available GPU types and prices
func (h *InstanceHandler) GetGPUPrices(c *gin.Context) {
	var prices []gin.H
	for gpuType, price := range gpuPrices {
		prices = append(prices, gin.H{
			"gpu_type":    gpuType,
			"hourly_rate": price,
		})
	}
	c.JSON(http.StatusOK, gin.H{"prices": prices})
}
