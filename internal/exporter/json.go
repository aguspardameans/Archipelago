package exporter

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func RowsToMap(rows *sql.Rows) ([]map[string]interface{}, error) {

	columns, _ := rows.Columns()
	var results []map[string]interface{}

	for rows.Next() {

		values := make([]interface{}, len(columns))
		ptrs := make([]interface{}, len(columns))

		for i := range values {
			ptrs[i] = &values[i]
		}

		rows.Scan(ptrs...)

		row := make(map[string]interface{})

		for i, col := range columns {
			row[col] = values[i]
		}

		results = append(results, row)
	}

	return results, nil
}

func SaveJSON(dir, report string, data interface{}) (string, error) {

	os.MkdirAll(dir, os.ModePerm)

	filename := fmt.Sprintf("%s_%d.json", report, time.Now().Unix())

	path := filepath.Join(dir, filename)

	file, err := os.Create(path)
	if err != nil {
		return "", err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	err = encoder.Encode(data)

	return path, err
}
