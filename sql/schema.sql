-- ============================================================
-- Medallion Architecture Layers
-- ============================================================

CREATE Database nyc_taxi_analytics
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
USE nyc_taxi_analytics;




-- Bronze: Raw ingestion layer.
-- Stores data exactly as received from source systems,
-- with no cleaning, filtering, or transformation applied.

CREATE TABLE bronze (
    id INT AUTO_INCREMENT PRIMARY KEY,
    VendorID INT,
    tpep_pickup_datetime DATETIME,
    tpep_dropoff_datetime DATETIME,
    passenger_count DECIMAL(5,2),  
    trip_distance DECIMAL(10,2),   
    RatecodeID DECIMAL(5,2),      
    store_and_fwd_flag VARCHAR(1),
    PULocationID INT,
    DOLocationID INT,
    payment_type INT,
    fare_amount DECIMAL(10,2),
    extra DECIMAL(10,2),
    mta_tax DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    tolls_amount DECIMAL(10,2),
    improvement_surcharge DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    congestion_surcharge DECIMAL(10,2),
    Airport_fee DECIMAL(10,2),
    cbd_congestion_fee DECIMAL(10,2), 
 
 
    _ingest_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _source_file VARCHAR(255),
    _row_hash CHAR(64),
    _ingest_date DATE GENERATED ALWAYS AS (DATE(_ingest_timestamp)) STORED,


    INDEX idx_pickup_datetime (tpep_pickup_datetime),
    INDEX idx_pulocation (PULocationID),
    INDEX idx_dolocation (DOLocationID),
    INDEX idx_vendor (VendorID)
);
------------------------------------------------------------------------------------

-- Silver: Cleansed and conformed layer.
-- Data is validated, deduplicated, standardized, and joined
-- across sources into a trusted, query-ready form.

CREATE TABLE silver (
    trip_id INT AUTO_INCREMENT PRIMARY KEY,
    
    vendor_id INT,
    pickup_datetime DATETIME,
    dropoff_datetime DATETIME,
    
    passenger_count INT,
    trip_distance DECIMAL(10,2),
    rate_code_id INT,
    store_and_fwd_flag VARCHAR(1),
    pickup_location_id INT,
    dropoff_location_id INT,
    payment_type INT,
    
    fare_amount DECIMAL(10,2),
    extra DECIMAL(10,2),
    mta_tax DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    tolls_amount DECIMAL(10,2),
    improvement_surcharge DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    congestion_surcharge DECIMAL(10,2),
    airport_fee DECIMAL(10,2),
    cbd_congestion_fee DECIMAL(10,2),
    
    trip_duration_minutes INT GENERATED ALWAYS AS (
        TIMESTAMPDIFF(MINUTE, pickup_datetime, dropoff_datetime)
    ) STORED,
    
    avg_speed_mph DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE 
            WHEN TIMESTAMPDIFF(MINUTE, pickup_datetime, dropoff_datetime) > 0 
            THEN trip_distance / (TIMESTAMPDIFF(MINUTE, pickup_datetime, dropoff_datetime) / 60)
            ELSE NULL 
        END
    ) STORED,
    
    pickup_hour INT GENERATED ALWAYS AS (HOUR(pickup_datetime)) STORED,
    pickup_day_of_week INT GENERATED ALWAYS AS (DAYOFWEEK(pickup_datetime)) STORED,
    pickup_month INT GENERATED ALWAYS AS (MONTH(pickup_datetime)) STORED,
    pickup_year INT GENERATED ALWAYS AS (YEAR(pickup_datetime)) STORED,
    
    time_of_day VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN HOUR(pickup_datetime) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN HOUR(pickup_datetime) BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN HOUR(pickup_datetime) BETWEEN 17 AND 20 THEN 'Evening'
            WHEN HOUR(pickup_datetime) BETWEEN 21 AND 23 THEN 'Night'
            ELSE 'Late Night'
        END
    ) STORED,
    
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors VARCHAR(500),
    quality_score INT DEFAULT 100,
    
    _processed_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    _bronze_source_id INT, 
    
    INDEX idx_pickup_datetime (pickup_datetime),
    INDEX idx_vendor (vendor_id),
    INDEX idx_location (pickup_location_id, dropoff_location_id),
    INDEX idx_valid (is_valid),
    INDEX idx_hour (pickup_hour),
    INDEX idx_day (pickup_day_of_week)
);
------------------------------------------------------------------------------------

-- Gold: Curated business layer.
-- Aggregated, enriched, business-ready data modeled for
-- reporting, analytics, dashboards, and ML consumption.

CREATE TABLE gold_daily_metrics (
    trip_date DATE PRIMARY KEY,
    total_trips INT,
    total_passengers INT,
    avg_passengers DECIMAL(5,2),
    total_revenue DECIMAL(15,2),
    avg_fare DECIMAL(10,2),
    total_tips DECIMAL(15,2),
    avg_tip DECIMAL(10,2),
    tip_percentage DECIMAL(5,2),
    avg_trip_distance DECIMAL(10,2),
    total_distance DECIMAL(15,2),
    trips_with_tips INT,
    tip_rate_percentage DECIMAL(5,2)
);


CREATE TABLE gold_monthly_summary (
    year_months VARCHAR(7) PRIMARY KEY,
    year INT,
    month INT,
    month_name VARCHAR(20),
    total_trips INT,
    total_passengers INT,
    total_revenue DECIMAL(15,2),
    avg_fare DECIMAL(10,2),
    total_tips DECIMAL(15,2),
    avg_tip DECIMAL(10,2),
    tip_percentage DECIMAL(5,2),
    avg_trip_distance DECIMAL(10,2),
    total_distance DECIMAL(15,2),
    active_days INT,
    avg_daily_trips INT,
    avg_daily_revenue DECIMAL(15,2)
);

CREATE TABLE gold_monthly_summary (
    year_monthly VARCHAR(7) PRIMARY KEY,
    year INT,
    month INT,
    month_name VARCHAR(20),
    total_trips INT,
    total_passengers INT,
    total_revenue DECIMAL(15,2),
    avg_fare DECIMAL(10,2),
    total_tips DECIMAL(15,2),
    avg_tip DECIMAL(10,2),
    tip_percentage DECIMAL(5,2),
    avg_trip_distance DECIMAL(10,2),
    total_distance DECIMAL(15,2),
    active_days INT,
    avg_daily_trips INT,
    avg_daily_revenue DECIMAL(15,2)
);

CREATE TABLE gold_location_performance (
    location_id INT PRIMARY KEY,
    total_pickups INT,
    total_passengers INT,
    total_revenue DECIMAL(15,2),
    avg_fare DECIMAL(10,2),
    avg_trip_distance DECIMAL(10,2),
    avg_tip DECIMAL(10,2),
    tip_percentage DECIMAL(5,2),
    trips_with_tips INT,
    tip_rate DECIMAL(5,2),
    avg_passengers DECIMAL(5,2),
    avg_dollar_per_mile DECIMAL(10,2)
);

CREATE TABLE gold_payment_analysis (
    payment_type INT PRIMARY KEY,
    payment_type_name VARCHAR(50),
    total_trips INT,
    percentage DECIMAL(5,2),
    total_revenue DECIMAL(15,2),
    avg_fare DECIMAL(10,2),
    total_tips DECIMAL(15,2),
    avg_tip DECIMAL(10,2),
    tip_percentage DECIMAL(5,2),
    avg_trip_distance DECIMAL(10,2),
    avg_passengers DECIMAL(5,2)
);




-- Insertion 
INSERT INTO gold_daily_metrics (
    trip_date,
    total_trips,
    total_passengers,
    avg_passengers,
    total_revenue,
    avg_fare,
    total_tips,
    avg_tip,
    tip_percentage,
    avg_trip_distance,
    total_distance,
    trips_with_tips,
    tip_rate_percentage
)
SELECT 
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS total_trips,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(passenger_count), 2) AS avg_passengers,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(AVG(tip_amount), 2) AS avg_tip,
    ROUND((SUM(tip_amount) / NULLIF(SUM(fare_amount), 0)) * 100, 2) AS tip_percentage,
    ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
    ROUND(SUM(trip_distance), 2) AS total_distance,
    COUNT(CASE WHEN tip_amount > 0 THEN 1 END) AS trips_with_tips,
    ROUND(COUNT(CASE WHEN tip_amount > 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS tip_rate_percentage
FROM silver
WHERE is_valid = TRUE
GROUP BY DATE(pickup_datetime)
ORDER BY trip_date;



INSERT INTO gold_location_performance (
    location_id,
    total_pickups,
    total_passengers,
    total_revenue,
    avg_fare,
    avg_trip_distance,
    avg_tip,
    tip_percentage,
    trips_with_tips,
    tip_rate,
    avg_passengers,
    avg_dollar_per_mile
)
SELECT 
    pickup_location_id AS location_id,
    COUNT(*) AS total_pickups,
    SUM(passenger_count) AS total_passengers,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
    ROUND(AVG(tip_amount), 2) AS avg_tip,
    ROUND((SUM(tip_amount) / NULLIF(SUM(fare_amount), 0)) * 100, 2) AS tip_percentage,
    COUNT(CASE WHEN tip_amount > 0 THEN 1 END) AS trips_with_tips,
    ROUND(COUNT(CASE WHEN tip_amount > 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS tip_rate,
    ROUND(AVG(passenger_count), 2) AS avg_passengers,
    ROUND(AVG(total_amount / NULLIF(trip_distance, 0)), 2) AS avg_dollar_per_mile
FROM silver
WHERE is_valid = TRUE
  AND pickup_location_id IS NOT NULL
  AND pickup_location_id > 0
GROUP BY pickup_location_id
ORDER BY total_pickups DESC;

INSERT INTO gold_monthly_summary (
    year_monthly,
    year,
    month,
    month_name,
    total_trips,
    total_passengers,
    total_revenue,
    avg_fare,
    total_tips,
    avg_tip,
    tip_percentage,
    avg_trip_distance,
    total_distance,
    active_days,
    avg_daily_trips,
    avg_daily_revenue
)
SELECT 
    DATE_FORMAT(pickup_datetime, '%Y-%m') AS year_monthly,
    YEAR(pickup_datetime) AS year,
    MONTH(pickup_datetime) AS month,
    MONTHNAME(pickup_datetime) AS month_name,
    COUNT(*) AS total_trips,
    SUM(passenger_count) AS total_passengers,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(AVG(tip_amount), 2) AS avg_tip,
    ROUND((SUM(tip_amount) / NULLIF(SUM(fare_amount), 0)) * 100, 2) AS tip_percentage,
    ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
    ROUND(SUM(trip_distance), 2) AS total_distance,
    COUNT(DISTINCT DATE(pickup_datetime)) AS active_days,
    ROUND(COUNT(*) / COUNT(DISTINCT DATE(pickup_datetime)), 0) AS avg_daily_trips,
    ROUND(SUM(total_amount) / COUNT(DISTINCT DATE(pickup_datetime)), 2) AS avg_daily_revenue
FROM silver
WHERE is_valid = TRUE
GROUP BY 
    DATE_FORMAT(pickup_datetime, '%Y-%m'),
    YEAR(pickup_datetime),
    MONTH(pickup_datetime),
    MONTHNAME(pickup_datetime)
ORDER BY year_monthly;


INSERT INTO gold_payment_analysis (
    payment_type,
    payment_type_name,
    total_trips,
    percentage,
    total_revenue,
    avg_fare,
    total_tips,
    avg_tip,
    tip_percentage,
    avg_trip_distance,
    avg_passengers
)
SELECT 
    payment_type,
    CASE 
        WHEN payment_type = 1 THEN 'Credit Card'
        WHEN payment_type = 2 THEN 'Cash'
        WHEN payment_type = 3 THEN 'No Charge'
        WHEN payment_type = 4 THEN 'Dispute'
        WHEN payment_type = 5 THEN 'Unknown'
        WHEN payment_type = 6 THEN 'Voided Trip'
        ELSE 'Other'
    END AS payment_type_name,
    COUNT(*) AS total_trips,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM silver WHERE is_valid = TRUE), 2) AS percentage,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_fare,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(AVG(tip_amount), 2) AS avg_tip,
    ROUND((SUM(tip_amount) / NULLIF(SUM(fare_amount), 0)) * 100, 2) AS tip_percentage,
    ROUND(AVG(trip_distance), 2) AS avg_trip_distance,
    ROUND(AVG(passenger_count), 2) AS avg_passengers
FROM silver
WHERE is_valid = TRUE
  AND payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY total_trips DESC;

------------------------------------------------------------------------------------------------







