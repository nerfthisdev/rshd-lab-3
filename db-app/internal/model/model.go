package model

import "github.com/google/uuid"

type User struct {
	ID       uuid.UUID
	Name     string
	Email    string
	Address  string
	Password string
}

type Order struct {
	ID     int
	UserID uuid.UUID
	SKU    int
	Price  float64
}
