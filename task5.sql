-- ============================================================
-- BA TASK 5 - WEEK 5
-- Dynamic Portfolio Risk Arbitrage & Value-at-Risk (VaR)
-- Monte Carlo Simulator
-- ============================================================

-- 1. CREATE ASSET TABLE

CREATE TABLE assets (
    asset_id INT PRIMARY KEY,
    asset_name VARCHAR(100),
    current_price DECIMAL(15,4),
    volatility DECIMAL(10,6),
    expected_return DECIMAL(10,6)
);


-- 2. INSERT SAMPLE ASSETS

INSERT INTO assets
(asset_id, asset_name, current_price, volatility, expected_return)
VALUES
(1, 'Asset_001', 100.00, 0.20, 0.08),
(2, 'Asset_002', 150.00, 0.25, 0.10),
(3, 'Asset_003', 200.00, 0.18, 0.07),
(4, 'Asset_004', 120.00, 0.30, 0.12),
(5, 'Asset_005', 180.00, 0.22, 0.09);


-- ============================================================
-- 3. CREATE HISTORICAL PRICE TABLE
-- ============================================================

CREATE TABLE historical_prices (
    asset_id INT,
    trade_date DATE,
    closing_price DECIMAL(15,4),

    PRIMARY KEY (asset_id, trade_date),

    FOREIGN KEY (asset_id)
    REFERENCES assets(asset_id)
);


-- ============================================================
-- 4. SAMPLE HISTORICAL PRICES
-- ============================================================

INSERT INTO historical_prices
(asset_id, trade_date, closing_price)
VALUES
(1, '2026-01-01', 100.00),
(1, '2026-01-02', 102.00),
(1, '2026-01-03', 101.00),
(1, '2026-01-04', 104.00),
(1, '2026-01-05', 103.00),

(2, '2026-01-01', 150.00),
(2, '2026-01-02', 153.00),
(2, '2026-01-03', 151.00),
(2, '2026-01-04', 155.00),
(2, '2026-01-05', 157.00),

(3, '2026-01-01', 200.00),
(3, '2026-01-02', 198.00),
(3, '2026-01-03', 202.00),
(3, '2026-01-04', 205.00),
(3, '2026-01-05', 203.00),

(4, '2026-01-01', 120.00),
(4, '2026-01-02', 124.00),
(4, '2026-01-03', 122.00),
(4, '2026-01-04', 127.00),
(4, '2026-01-05', 125.00),

(5, '2026-01-01', 180.00),
(5, '2026-01-02', 182.00),
(5, '2026-01-03', 185.00),
(5, '2026-01-04', 183.00),
(5, '2026-01-05', 187.00);


-- ============================================================
-- 5. CALCULATE DAILY RETURNS
-- ============================================================

WITH price_data AS (
    SELECT
        asset_id,
        trade_date,
        closing_price,
        LAG(closing_price)
        OVER (
            PARTITION BY asset_id
            ORDER BY trade_date
        ) AS previous_price
    FROM historical_prices
)

SELECT
    asset_id,
    trade_date,
    closing_price,
    previous_price,

    CASE
        WHEN previous_price IS NOT NULL
        THEN (closing_price - previous_price)
             / previous_price
    END AS daily_return

FROM price_data
ORDER BY asset_id, trade_date;


-- ============================================================
-- 6. CALCULATE AVERAGE RETURN
-- ============================================================

WITH returns AS (
    SELECT
        asset_id,
        (closing_price -
         LAG(closing_price)
         OVER (
             PARTITION BY asset_id
             ORDER BY trade_date
         ))
        /
        LAG(closing_price)
        OVER (
            PARTITION BY asset_id
            ORDER BY trade_date
        ) AS daily_return
    FROM historical_prices
)

SELECT
    asset_id,
    AVG(daily_return) AS average_daily_return
FROM returns
WHERE daily_return IS NOT NULL
GROUP BY asset_id
ORDER BY asset_id;


-- ============================================================
-- 7. CALCULATE HISTORICAL VOLATILITY
-- ============================================================

WITH returns AS (
    SELECT
        asset_id,
        (
            closing_price -
            LAG(closing_price)
            OVER (
                PARTITION BY asset_id
                ORDER BY trade_date
            )
        )
        /
        LAG(closing_price)
        OVER (
            PARTITION BY asset_id
            ORDER BY trade_date
        ) AS daily_return
    FROM historical_prices
)

SELECT
    asset_id,
    STDDEV(daily_return)
    AS daily_volatility,

    STDDEV(daily_return) * SQRT(252)
    AS annualized_volatility

FROM returns
WHERE daily_return IS NOT NULL
GROUP BY asset_id
ORDER BY asset_id;


-- ============================================================
-- 8. CREATE PORTFOLIO TABLE
-- ============================================================

CREATE TABLE portfolio (
    portfolio_id INT,
    asset_id INT,
    quantity INT,
    portfolio_weight DECIMAL(10,6),

    PRIMARY KEY (portfolio_id, asset_id),

    FOREIGN KEY (asset_id)
    REFERENCES assets(asset_id)
);


-- ============================================================
-- 9. INSERT PORTFOLIO DATA
-- ============================================================

INSERT INTO portfolio
(portfolio_id, asset_id, quantity, portfolio_weight)
VALUES
(1, 1, 100, 0.20),
(1, 2, 80, 0.25),
(1, 3, 50, 0.20),
(1, 4, 100, 0.15),
(1, 5, 70, 0.20);


-- ============================================================
-- 10. CALCULATE PORTFOLIO VALUE
-- ============================================================

SELECT
    p.portfolio_id,

    SUM(
        p.quantity * a.current_price
    ) AS portfolio_value

FROM portfolio p

JOIN assets a
    ON p.asset_id = a.asset_id

GROUP BY p.portfolio_id;


-- ============================================================
-- 11. CALCULATE PORTFOLIO EXPECTED RETURN
-- ============================================================

SELECT
    p.portfolio_id,

    SUM(
        p.portfolio_weight *
        a.expected_return
    ) AS expected_portfolio_return

FROM portfolio p

JOIN assets a
    ON p.asset_id = a.asset_id

GROUP BY p.portfolio_id;


-- ============================================================
-- 12. CALCULATE PORTFOLIO VOLATILITY
-- ============================================================

SELECT
    p.portfolio_id,

    SQRT(
        SUM(
            POWER(
                p.portfolio_weight *
                a.volatility,
                2
            )
        )
    ) AS portfolio_volatility

FROM portfolio p

JOIN assets a
    ON p.asset_id = a.asset_id

GROUP BY p.portfolio_id;


-- ============================================================
-- 13. CREATE COVARIANCE MATRIX TABLE
-- ============================================================

CREATE TABLE covariance_matrix (
    asset_i INT,
    asset_j INT,
    covariance_value DECIMAL(18,10),

    PRIMARY KEY (asset_i, asset_j)
);


-- ============================================================
-- 14. INSERT SAMPLE COVARIANCE VALUES
-- ============================================================

INSERT INTO covariance_matrix
(asset_i, asset_j, covariance_value)
VALUES
(1,1,0.0400),
(1,2,0.0120),
(1,3,0.0080),
(1,4,0.0150),
(1,5,0.0100),

(2,1,0.0120),
(2,2,0.0625),
(2,3,0.0110),
(2,4,0.0200),
(2,5,0.0140),

(3,1,0.0080),
(3,2,0.0110),
(3,3,0.0324),
(3,4,0.0090),
(3,5,0.0120),

(4,1,0.0150),
(4,2,0.0200),
(4,3,0.0090),
(4,4,0.0900),
(4,5,0.0180),

(5,1,0.0100),
(5,2,0.0140),
(5,3,0.0120),
(5,4,0.0180),
(5,5,0.0484);


-- ============================================================
-- 15. DISPLAY COVARIANCE MATRIX
-- ============================================================

SELECT
    asset_i,
    asset_j,
    covariance_value
FROM covariance_matrix
ORDER BY asset_i, asset_j;


-- ============================================================
-- 16. CALCULATE PORTFOLIO VARIANCE
-- ============================================================

SELECT
    SUM(
        p1.portfolio_weight *
        p2.portfolio_weight *
        c.covariance_value
    ) AS portfolio_variance

FROM portfolio p1

JOIN portfolio p2
    ON p1.portfolio_id = p2.portfolio_id

JOIN covariance_matrix c
    ON c.asset_i = p1.asset_id
    AND c.asset_j = p2.asset_id

WHERE p1.portfolio_id = 1;


-- ============================================================
-- 17. CALCULATE PORTFOLIO STANDARD DEVIATION
-- ============================================================

SELECT
    SQRT(
        SUM(
            p1.portfolio_weight *
            p2.portfolio_weight *
            c.covariance_value
        )
    ) AS portfolio_standard_deviation

FROM portfolio p1

JOIN portfolio p2
    ON p1.portfolio_id = p2.portfolio_id

JOIN covariance_matrix c
    ON c.asset_i = p1.asset_id
    AND c.asset_j = p2.asset_id

WHERE p1.portfolio_id = 1;


-- ============================================================
-- 18. CALCULATE 99% PARAMETRIC VAR
-- ============================================================

WITH portfolio_data AS (
    SELECT
        SUM(
            p1.portfolio_weight *
            p2.portfolio_weight *
            c.covariance_value
        ) AS variance
    FROM portfolio p1

    JOIN portfolio p2
        ON p1.portfolio_id = p2.portfolio_id

    JOIN covariance_matrix c
        ON c.asset_i = p1.asset_id
        AND c.asset_j = p2.asset_id

    WHERE p1.portfolio_id = 1
),

portfolio_value AS (
    SELECT
        SUM(
            p.quantity *
            a.current_price
        ) AS total_value
    FROM portfolio p

    JOIN assets a
        ON p.asset_id = a.asset_id

    WHERE p.portfolio_id = 1
)

SELECT

    total_value,

    SQRT(variance)
    AS portfolio_volatility,

    -- 99% confidence Z-score = 2.3263

    total_value *
    SQRT(variance) *
    2.3263
    AS VAR_99

FROM portfolio_data,
     portfolio_value;


-- ============================================================
-- 19. EXPECTED SHORTFALL APPROXIMATION
-- ============================================================

WITH portfolio_data AS (
    SELECT
        SUM(
            p1.portfolio_weight *
            p2.portfolio_weight *
            c.covariance_value
        ) AS variance
    FROM portfolio p1

    JOIN portfolio p2
        ON p1.portfolio_id = p2.portfolio_id

    JOIN covariance_matrix c
        ON c.asset_i = p1.asset_id
        AND c.asset_j = p2.asset_id

    WHERE p1.portfolio_id = 1
),

portfolio_value AS (
    SELECT
        SUM(
            p.quantity *
            a.current_price
        ) AS total_value
    FROM portfolio p

    JOIN assets a
        ON p.asset_id = a.asset_id
)

SELECT

    total_value *
    SQRT(variance) *
    2.6652
    AS expected_shortfall_99

FROM portfolio_data,
     portfolio_value;


-- ============================================================
-- 20. PORTFOLIO RISK SUMMARY
-- ============================================================

SELECT

    p.portfolio_id,

    SUM(
        p.quantity *
        a.current_price
    ) AS portfolio_value,

    SUM(
        p.portfolio_weight *
        a.expected_return
    ) AS expected_return,

    SQRT(
        SUM(
            p1.portfolio_weight *
            p2.portfolio_weight *
            c.covariance_value
        )
    ) AS portfolio_volatility

FROM portfolio p

JOIN assets a
    ON p.asset_id = a.asset_id

JOIN portfolio p1
    ON p.portfolio_id = p1.portfolio_id

JOIN portfolio p2
    ON p1.portfolio_id = p2.portfolio_id

JOIN covariance_matrix c
    ON c.asset_i = p1.asset_id
    AND c.asset_j = p2.asset_id

WHERE p.portfolio_id = 1

GROUP BY p.portfolio_id;


-- ============================================================
-- END OF WEEK-5 BA TASK
-- ============================================================
