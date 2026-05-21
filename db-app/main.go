package main

import (
	"context"
	"errors"
	"flag"
	"log/slog"
	"strconv"

	"github.com/jackc/pgx/v5"
	"github.com/nerfthisdev/db-app/internal/repository"
)

var (
	dsnPg1 = "postgres://postgres:secret123@127.0.0.1:5432/mydb"
	dsnPg2 = "postgres://postgres:secret123@127.0.0.1:5433/mydb"
)

var ErrorInvalidArgs = errors.New("error: not enough arguments")

func main() {
	var pgFlag int
	var conn *pgx.Conn
	var err error
	flag.IntVar(&pgFlag, "pg", 1, "-pg")
	flag.Parse()

	args := flag.Args()

	logger := slog.Default()

	ctx := context.Background()

	if pgFlag == 1 {
		conn, err = pgx.Connect(ctx, dsnPg1)
	} else {
		conn, err = pgx.Connect(ctx, dsnPg2)
	}

	if err != nil {
		logger.Error("error connecting to db", "error", err)
		return
	}
	defer conn.Close(ctx)

	repo := repository.NewRepository(conn)

	if args[0] == "seed" {
		if len(args) != 2 {
			logger.Error("not enough arguments", "error", ErrorInvalidArgs)
			return
		}

		n, err := strconv.Atoi(args[1])
		if err != nil {
			logger.Error("invalid argument", "error", ErrorInvalidArgs)
			return
		}

		if err := repo.Seed(ctx, n); err != nil {
			logger.Error("error seeding", "error", err)
		}
		logger.Info("seeded users and orders", "n", n)
	}

	if args[0] == "read" {
		if len(args) != 2 {
			logger.Error("not enough arguments", "error", ErrorInvalidArgs)
			return
		}

		users, err := repo.ReadUsers(ctx, 10)
		_ = users
		if err != nil {
			logger.Error("error reading", "error", err)
		}

	}
}
