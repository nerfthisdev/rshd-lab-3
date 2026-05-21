package repository

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/nerfthisdev/db-app/internal/model"
)

type Repository struct {
	db *pgx.Conn
}

func NewRepository(db *pgx.Conn) *Repository {
	return &Repository{db: db}
}

func (r *Repository) ReadUsers(ctx context.Context, n int) ([]model.User, error) {
	queryString := `
	SELECT 
	    user_id as id,
		name,
		email,
		address,
		password FROM users LIMIT ($1)
	`

	rows, err := r.db.Query(ctx, queryString, n)
	if err != nil {
		return []model.User{}, err
	}

	users, err := pgx.CollectRows(rows, pgx.RowToStructByName[model.User])
	if err != nil {
		return nil, err
	}

	return users, nil
}

func (r *Repository) Seed(ctx context.Context, n int) error {
	users := model.GenerateUsers(n)

	orders := model.GenerateOrders(users)

	err := r.seedUsers(ctx, users)
	if err != nil {
		return err
	}

	err = r.seedOrders(ctx, orders)
	if err != nil {
		return err
	}

	return nil
}

func (r *Repository) seedUsers(ctx context.Context, users []model.User) error {
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

	br := r.db.SendBatch(ctx, batch)
	defer br.Close()

	for range users {
		if _, err := br.Exec(); err != nil {
			return err
		}
	}
	return nil
}

func (r *Repository) seedOrders(ctx context.Context, orders []model.Order) error {
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

	br := r.db.SendBatch(ctx, batch)
	defer br.Close()

	for range orders {
		if _, err := br.Exec(); err != nil {
			return err
		}
	}
	return nil
}
