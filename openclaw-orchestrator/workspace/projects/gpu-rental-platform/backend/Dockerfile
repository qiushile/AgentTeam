# Dockerfile for GPU Cloud Platform Backend
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git ca-certificates

# Copy go module files first (layer caching)
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /gpucloud-server ./cmd/server/

# Final minimal image
FROM alpine:3.19

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

COPY --from=builder /gpucloud-server .

EXPOSE 8080

ENTRYPOINT ["./gpucloud-server"]
