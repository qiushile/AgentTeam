package handler

import (
	"net/http"
	"strconv"

	"gpucloud/internal/service"

	"github.com/gin-gonic/gin"
)

type GPUHandler struct {
	gpuSvc *service.GPUService
}

func NewGPUHandler(gpuSvc *service.GPUService) *GPUHandler {
	return &GPUHandler{gpuSvc: gpuSvc}
}

func (h *GPUHandler) ListModels(c *gin.Context) {
	models, err := h.gpuSvc.ListModels(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list GPU models"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  models,
		"total": len(models),
	})
}

func (h *GPUHandler) GetModel(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid gpu model id"})
		return
	}

	model, err := h.gpuSvc.GetModel(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, model)
}
