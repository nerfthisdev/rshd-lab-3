package seed

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/nerfthisdev/db-app/internal/model"
)

//
// type User struct {
// 	ID       uuid.UUID
// 	Name     string
// 	Email    string
// 	Address  string
// 	Password string
// }
//
// type Order struct {
// 	ID     int
// 	UserID uuid.UUID
// 	SKU    int
// 	Price  float64
// }

type Seeder struct {
	db *pgx.Conn
}

func NewSeeder(db *pgx.Conn) *Seeder {
	return &Seeder{db: db}
}

func (s *Seeder) Seed(ctx context.Context) error {
	n := 50
	users := model.GenerateUsers(n)

	orders := model.GenerateOrders(users)

	err := s.seedUsers(ctx, users)
	if err != nil {
		return err
	}

	err = s.seedOrders(ctx, orders)
	if err != nil {
		return err
	}

	return nil
}

func (s *Seeder) seedUsers(ctx context.Context, users []model.User) error {
	queryString := `INSERT
	INTO users (user_id, name, email, address, password)
	VALUES ($1, $2, $3, $4, $5)`

	batch := &pgx.Batch{}

	for _, u := range users {
		batch.Queue(
			queryString,
			u.ID,
			u.Name,
			u.Email,
			u.Address,
			u.Password,
		)
	}

	br := s.db.SendBatch(ctx, batch)
	defer br.Close()

	for range users {
		if _, err := br.Exec(); err != nil {
			return err
		}
	}
	return nil
}

func (s *Seeder) seedOrders(ctx context.Context, orders []model.Order) error {
	queryString := `INSERT
	INTO orders (user_id, sku, price)
	VALUES ($1, $2, $3)`

	batch := &pgx.Batch{}

	for _, o := range orders {
		batch.Queue(
			queryString,
			o.UserID,
			o.SKU,
			o.Price,
		)
	}

	br := s.db.SendBatch(ctx, batch)
	defer br.Close()

	for range orders {
		if _, err := br.Exec(); err != nil {
			return err
		}
	}
	return nil
}
