package main

import (
	"context"
	"log/slog"

	"github.com/jackc/pgx/v5"
)

var (
	dsnPg1 = "postgres://mainuser:mypassword@localhost:5432/mydb"
	dsnPg2 = ""
)

func main() {
	logger := slog.Default()

	connPg1, err := pgx.Connect(context.Background(), dsnPg1)
	if err != nil {
		logger.Error("error connecting to db", "error", err)
	}

	defer connPg1.Close(context.Background())
}
