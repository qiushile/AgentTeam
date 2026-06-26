package service

import (
	"testing"
)

func TestNewGPUService(t *testing.T) {
	// This is a placeholder test - full tests would require mock DB
	svc := NewGPUService(nil)
	if svc == nil {
		t.Error("NewGPUService returned nil")
	}
}

func TestNewInstanceService(t *testing.T) {
	svc := NewInstanceService(nil, nil, NewGPUService(nil))
	if svc == nil {
		t.Error("NewInstanceService returned nil")
	}
}

func TestNewBillingService(t *testing.T) {
	svc := NewBillingService(nil, nil)
	if svc == nil {
		t.Error("NewBillingService returned nil")
	}
}

func TestNewMonitorService(t *testing.T) {
	svc := NewMonitorService(nil)
	if svc == nil {
		t.Error("NewMonitorService returned nil")
	}
}

func TestNewUserService(t *testing.T) {
	svc := NewUserService(nil, nil)
	if svc == nil {
		t.Error("NewUserService returned nil")
	}
}
