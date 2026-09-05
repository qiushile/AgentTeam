package handler

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type OrderHandler struct {
	DB *sql.DB
}

func NewOrderHandler(db *sql.DB) *OrderHandler {
	return &OrderHandler{DB: db}
}

// CreateOrder creates a new recharge order
func (h *OrderHandler) CreateOrder(c *gin.Context) {
	userID := c.GetInt64("user_id")

	var req struct {
		Amount    float64 `json:"amount" binding:"required,gt=0"`
		PayMethod string  `json:"pay_method" binding:"required"` // alipay, wechat, card
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var orderID int64
	err := h.DB.QueryRow(`
		INSERT INTO orders (user_id, amount, status, pay_method, description)
		VALUES ($1, $2, 'pending', $3, $4) RETURNING id
	`, userID, req.Amount, req.PayMethod, "account recharge").Scan(&orderID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create order"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"order_id":    orderID,
		"amount":      req.Amount,
		"status":      "pending",
		"pay_method":  req.PayMethod,
		"description": "account recharge",
	})
}

// ListOrders returns user's order history
func (h *OrderHandler) ListOrders(c *gin.Context) {
	userID := c.GetInt64("user_id")

	rows, err := h.DB.Query(`
		SELECT id, amount, status, pay_method, description, created_at, paid_at
		FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var orders []gin.H
	for rows.Next() {
		var order struct {
			ID          int64     `json:"id"`
			Amount      float64   `json:"amount"`
			Status      string    `json:"status"`
			PayMethod   string    `json:"pay_method"`
			Description string    `json:"description"`
			CreatedAt   time.Time `json:"created_at"`
			PaidAt      *time.Time `json:"paid_at"`
		}
		if err := rows.Scan(&order.ID, &order.Amount, &order.Status, &order.PayMethod,
			&order.Description, &order.CreatedAt, &order.PaidAt); err != nil {
			continue
		}
		orders = append(orders, gin.H{
			"id":          order.ID,
			"amount":      order.Amount,
			"status":      order.Status,
			"pay_method":  order.PayMethod,
			"description": order.Description,
			"created_at":  order.CreatedAt,
			"paid_at":     order.PaidAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"orders": orders})
}

// GetUsage returns usage logs for the current user
func (h *OrderHandler) GetUsage(c *gin.Context) {
	userID := c.GetInt64("user_id")

	rows, err := h.DB.Query(`
		SELECT ul.id, ul.instance_id, gi.gpu_type, ul.start_time, ul.end_time, ul.duration_hours, ul.cost, ul.status
		FROM usage_logs ul
		LEFT JOIN gpu_instances gi ON ul.instance_id = gi.id
		WHERE ul.user_id = $1
		ORDER BY ul.start_time DESC
		LIMIT 50
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}
	defer rows.Close()

	var logs []gin.H
	for rows.Next() {
		var entry struct {
			ID          int64      `json:"id"`
			InstanceID  int64      `json:"instance_id"`
			GPUType     *string    `json:"gpu_type"`
			StartTime   time.Time  `json:"start_time"`
			EndTime     *time.Time `json:"end_time"`
			DurationH   float64    `json:"duration_hours"`
			Cost        float64    `json:"cost"`
			Status      string     `json:"status"`
		}
		if err := rows.Scan(&entry.ID, &entry.InstanceID, &entry.GPUType,
			&entry.StartTime, &entry.EndTime, &entry.DurationH, &entry.Cost, &entry.Status); err != nil {
			continue
		}
		logs = append(logs, gin.H{
			"id":             entry.ID,
			"instance_id":    entry.InstanceID,
			"gpu_type":       entry.GPUType,
			"start_time":     entry.StartTime,
			"end_time":       entry.EndTime,
			"duration_hours": entry.DurationH,
			"cost":           entry.Cost,
			"status":         entry.Status,
		})
	}

	c.JSON(http.StatusOK, gin.H{"usage_logs": logs})
}
