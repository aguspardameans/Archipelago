package main

import (
	"context"
	"database/sql"
	"flag"
	"log"
	"os"
	"time"

	"Archipelago/internal/db"
	"Archipelago/internal/exporter"
	"Archipelago/internal/queries"
)

func main() {

	report := flag.String("report", "", "Report name (cohort, product)")
	output := flag.String("output", "./reports", "Output directory")
	flag.Parse()

	if *report == "" {
		log.Fatal("Please specify report using --report")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable not set")
	}

	database, err := db.Connect(dbURL)
	if err != nil {
		log.Fatalf("DB connection error: %v", err)
	}
	defer database.Close()

	var query string

	switch *report {
	case "cohort":
		query = queries.CohortQuery
	case "product":
		query = queries.ProductPerformanceQuery
	default:
		log.Fatalf("Unknown report: %s", *report)
	}

	start := time.Now()

	rows, err := database.QueryContext(context.Background(), query)
	if err != nil {
		log.Fatalf("Query error: %v", err)
	}
	defer rows.Close()

	data, err := exporter.RowsToMap(rows)
	if err != nil {
		log.Fatalf("Export error: %v", err)
	}

	file, err := exporter.SaveJSON(*output, *report, data)
	if err != nil {
		log.Fatalf("File error: %v", err)
	}

	log.Printf("Report generated: %s", file)
	log.Printf("Execution time: %v", time.Since(start))
}
