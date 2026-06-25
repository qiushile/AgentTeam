package handler

import (
	"net/http"

	"gpucloud/internal/service"

	"github.com/gin-gonic/gin"
)

type MonitorHandler struct {
	monitorSvc *service.MonitorService
}

func NewMonitorHandler(monitorSvc *service.MonitorService) *MonitorHandler {
	return &MonitorHandler{monitorSvc: monitorSvc}
}

func (h *MonitorHandler) GetMetrics(c *gin.Context) {
	instanceID := c.Param("id")

	metrics, err := h.monitorSvc.GetMetrics(c.Request.Context(), instanceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get metrics"})
		return
	}

	c.JSON(http.StatusOK, metrics)
}
