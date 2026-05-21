package model

import (
	"encoding/base64"
	"fmt"

	"github.com/brianvoe/gofakeit/v7"
	"github.com/google/uuid"
)

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

func (u *User) String() string {
	return fmt.Sprintf("ID: %s Name: %s, Email: %s, Address: %s, Password: %s",
		u.ID,
		u.Name,
		u.Email,
		u.Address,
		u.Password,
	)
}

func GenerateUsers(n int) []User {
	userS := make([]User, 0, n)

	for range n {
		randomPass := gofakeit.Word() + fmt.Sprint(gofakeit.Number(1000, 9999))
		passEnc := base64.StdEncoding.EncodeToString([]byte(randomPass))

		u := User{
			ID:       uuid.New(),
			Name:     gofakeit.Name(),
			Email:    gofakeit.Email(),
			Address:  gofakeit.Address().Address,
			Password: passEnc,
		}

		userS = append(userS, u)
	}

	return userS
}

func GenerateOrders(users []User) []Order {
	n := len(users)
	orderS := make([]Order, 0, n)

	for i := range n {

		u := users[i]
		o1 := Order{
			UserID: u.ID,
			SKU:    gofakeit.Int(),
			Price:  gofakeit.Float64(),
		}

		o2 := Order{
			UserID: u.ID,
			SKU:    gofakeit.Int(),
			Price:  gofakeit.Float64(),
		}

		orderS = append(orderS, o1)
		orderS = append(orderS, o2)
	}

	return orderS
}
