package reader

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/nerfthisdev/db-app/internal/model"
)

type Reader struct {
	db *pgx.Conn
}

func NewReader(db *pgx.Conn) *Reader {
	return &Reader{db: db}
}

func (r *Reader) ReadUsers(ctx context.Context, n int) []model.User {
	var users []model.User
	queryString := `
	SELECT 
	    user_id,
		name,
		email,
		address,
		password FROM users
	`

	rows := r.db.QueryRow(ctx, queryString)

	err := rows.Scan(&users)
	if err != nil {
		println("error")
	}

	return users
}
