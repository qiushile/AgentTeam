package handler

import (
	"net/http"
	"strconv"

	"gpucloud/internal/models"
	"gpucloud/internal/service"

	"github.com/gin-gonic/gin"
)

type BillingHandler struct {
	billingSvc *service.BillingService
}

func NewBillingHandler(billingSvc *service.BillingService) *BillingHandler {
	return &BillingHandler{billingSvc: billingSvc}
}

func (h *BillingHandler) GetBalance(c *gin.Context) {
	userID := c.GetString("user_id")

	balance, err := h.billingSvc.GetBalance(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get balance"})
		return
	}

	c.JSON(http.StatusOK, balance)
}

func (h *BillingHandler) ListRecords(c *gin.Context) {
	userID := c.GetString("user_id")

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	records, err := h.billingSvc.ListRecords(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list records"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  records,
		"total": len(records),
	})
}

func (h *BillingHandler) Recharge(c *gin.Context) {
	userID := c.GetString("user_id")

	var req models.RechargeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := h.billingSvc.Recharge(c.Request.Context(), userID, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "recharge failed"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "recharge successful",
		"amount":  req.Amount,
	})
}
