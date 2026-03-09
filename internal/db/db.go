package db

import (
	"database/sql"
	_ "github.com/lib/pq"
)

func Connect(url string) (*sql.DB, error) {

	db, err := sql.Open("postgres", url)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	return db, db.Ping()
}
