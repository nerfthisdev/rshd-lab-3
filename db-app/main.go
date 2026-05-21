package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"

	"github.com/jackc/pgx/v5"
	"github.com/nerfthisdev/db-app/internal/reader"
	"github.com/nerfthisdev/db-app/internal/seed"
)

var (
	dsnPg1 = "postgres://postgres:secret123@127.0.0.1:5432/mydb"
	dsnPg2 = ""
)

func main() {
	var seedFlag bool
	flag.BoolVar(&seedFlag, "seed", false, "-seed")
	flag.Parse()

	logger := slog.Default()

	ctx := context.Background()

	connPg1, err := pgx.Connect(ctx, dsnPg1)
	if err != nil {
		logger.Error("error connecting to db", "error", err)
		return
	}
	defer connPg1.Close(ctx)

	if seedFlag {
		seeder := seed.NewSeeder(connPg1)
		if err := seeder.Seed(ctx); err != nil {
			logger.Error("error seeding", "error", err)
		}
	}

	reader := reader.NewReader(connPg1)

	users := reader.ReadUsers(ctx, 10)

	fmt.Printf("%v", users)
}
