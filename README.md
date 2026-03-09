# Data Automation & Retrieval Engineer 

This repository contains the implementation of the **Data Automation & Retrieval Engineer technical assessment**.

The goal of this project is to demonstrate:

* Advanced SQL analytics capabilities
* PostgreSQL data retrieval automation
* Go-based CLI data extraction tool
* Query optimization and analytical thinking
* Clean project structure and documentation

---

# Project Structure

```
Archipelago
│
├── cmd
│   └── main.go                # CLI entry point
│
├── internal
│   ├── db
│   │   └── db.go              # PostgreSQL connection
│   │
│   ├── exporter
│   │   └── json.go            # Export query results to JSON
│   │
│   ├── queries
│   │   ├── cohort.go          # Cohort report query
│   │   └── product.go         # Product performance report
│
├── queries
│   ├── 1_Customer-Cohort-Analysis.sql
│   ├── 2_Product-Performance.sql
│   ├── 3_Customer-Segmentation.sql
│   ├── 4_Advanced-Sales-Trend-Analysis.sql
│   ├── 5_Inventory-Turnover-and-Stock.sql
│   └── 6_Customer-Purchase-Pattern.sql
│
├── docs
│   ├── 1.1_Schema-Analysis.md
│   ├── 1.2_Write_Complex_SQL_Queries.md
│   ├── 3.1_Automation_Opportunity.md
│   ├── 3.2_Query_Performance_Debugging.md
│   └── 3.3_REST_API_Integration.md
│
├── output
│   └── sample JSON outputs
│
└── README.md
```

---

# Part 1 – Complex SQL Queries

The repository contains **six analytical SQL queries** designed to simulate real-world business analytics.

These queries demonstrate the use of:

* CTEs
* Window functions
* Advanced aggregations
* Time-series analysis
* Statistical calculations
* Customer segmentation

---

## Implemented SQL Reports

### 1. Customer Cohort Analysis

Shows:

* Monthly customer acquisition
* First-month revenue
* Running total of customers
* Retention rate

Techniques used:

* `DATE_TRUNC`
* `SUM() OVER`
* Cohort analysis logic

---

### 2. Product Performance Analysis

Shows:

* Product revenue
* Units sold
* Revenue ranking within category
* Percentage of category revenue
* Month-over-month comparison
* Top 20% product identification

Techniques used:

* `RANK()`
* `PERCENT_RANK()`
* `SUM() OVER(PARTITION BY)`

---

### 3. Customer Segmentation (RFM)

Implements **RFM segmentation**:

* Recency
* Frequency
* Monetary value

Segments customers into:

* Champions
* Loyal
* At Risk
* Lost

Techniques used:

* `NTILE()`
* `CASE`
* Multi-step CTE logic

---

### 4. Advanced Sales Trend Analysis

Calculates:

* Daily sales
* 7-day moving averages
* Sales anomalies

Techniques used:

* `generate_series()`
* Window frame functions

---

### 5. Inventory Turnover Analysis

Calculates:

* Sales velocity
* Days until stockout
* Reorder recommendations

Techniques used:

* Complex CASE logic
* Mathematical forecasting

---

### 6. Customer Purchase Pattern Analysis

Analyzes customer purchasing behavior:

* Average days between orders
* Standard deviation of ordering behavior
* Purchase category preference
* Trend detection

Techniques used:

* `LAG()`
* `STDDEV()`
* Ranking logic

---

# Part 2 – Go Automation Tool

A command-line tool written in **Go** that automates data extraction from PostgreSQL and exports reports to JSON files.

---

## Core Features

* Connects to PostgreSQL database
* Executes analytical SQL queries
* Exports results to JSON files
* Logs execution details
* Handles errors gracefully

---

# Supported Reports

Currently automated reports:

| Report  | Description                |
| ------- | -------------------------- |
| cohort  | Customer cohort analysis   |
| product | Product performance report |

---

# Running the Tool

## 1. Set Database Connection

Example for Windows:

```
set DATABASE_URL=postgres://postgres:password@localhost:5432/yourdb?sslmode=disable
```

Example for Mac/Linux:

```
export DATABASE_URL=postgres://postgres:password@localhost:5432/yourdb?sslmode=disable
```

---

## 2. Run a Report

Example:

```
go run cmd/main.go --report=cohort
```

or

```
go run cmd/main.go --report=product
```

---

## 3. Output

Reports are exported as JSON files in the `output` folder.

Example:

```
output/
cohort_1712345678.json
product_1712345678.json
```

Example JSON output:

```
[
  {
    "cohort_month": "2024-01-01",
    "new_customers": 45
  }
]
```

---

# Configuration

The application supports database configuration via environment variable:

```
DATABASE_URL
```

Example format:

```
postgres://user:password@host:port/database?sslmode=disable
```

---

# Error Handling

The application includes:

* Graceful database connection handling
* Query execution error logging
* JSON export error detection

Execution time for each report is logged for monitoring performance.

---

# Optimization Considerations

The SQL queries are optimized for large datasets using:

* CTE-based query decomposition
* Window functions instead of nested subqueries
* Early filtering conditions
* Partition-based aggregations
* Reduced full-table scans

---

# Assumptions

* Only **completed orders** are considered in most analytical queries.
* Revenue is calculated from `order_items`.
* Time-based analytics assume consistent timestamps.

---

# Technologies Used

* PostgreSQL
* Go (Golang)
* Advanced SQL analytics

---

# Author

**Agus Pardamean**
