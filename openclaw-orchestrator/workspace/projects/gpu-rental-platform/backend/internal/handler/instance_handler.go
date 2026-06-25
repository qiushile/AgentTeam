package handler

import (
	"net/http"
	"strconv"

	"gpucloud/internal/models"
	"gpucloud/internal/service"

	"github.com/gin-gonic/gin"
)

type InstanceHandler struct {
	instanceSvc *service.InstanceService
}

func NewInstanceHandler(instanceSvc *service.InstanceService) *InstanceHandler {
	return &InstanceHandler{instanceSvc: instanceSvc}
}

func (h *InstanceHandler) ListInstances(c *gin.Context) {
	userID := c.GetString("user_id")

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	instances, err := h.instanceSvc.ListByUser(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list instances"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  instances,
		"total": len(instances),
	})
}

func (h *InstanceHandler) CreateInstance(c *gin.Context) {
	userID := c.GetString("user_id")

	var req models.CreateInstanceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	instance, err := h.instanceSvc.Create(c.Request.Context(), userID, req)
	if err != nil {
		status := http.StatusBadRequest
		if err.Error() == "insufficient balance, minimum 2 hours required" {
			status = http.StatusPaymentRequired
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, instance)
}

func (h *InstanceHandler) GetInstance(c *gin.Context) {
	userID := c.GetString("user_id")
	instanceID := c.Param("id")

	instance, err := h.instanceSvc.GetByID(c.Request.Context(), userID, instanceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, instance)
}

func (h *InstanceHandler) StartInstance(c *gin.Context) {
	userID := c.GetString("user_id")
	instanceID := c.Param("id")

	err := h.instanceSvc.Start(c.Request.Context(), userID, instanceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "instance starting"})
}

func (h *InstanceHandler) StopInstance(c *gin.Context) {
	userID := c.GetString("user_id")
	instanceID := c.Param("id")

	err := h.instanceSvc.Stop(c.Request.Context(), userID, instanceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "instance stopping"})
}

func (h *InstanceHandler) ReleaseInstance(c *gin.Context) {
	userID := c.GetString("user_id")
	instanceID := c.Param("id")

	err := h.instanceSvc.Release(c.Request.Context(), userID, instanceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "instance released"})
}

func (h *InstanceHandler) GetSSHInfo(c *gin.Context) {
	userID := c.GetString("user_id")
	instanceID := c.Param("id")

	sshInfo, err := h.instanceSvc.GetSSHInfo(c.Request.Context(), userID, instanceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sshInfo)
}
