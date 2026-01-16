-- Считает общее количество клиентов
SELECT COUNT(*) AS customers_count
FROM customers;
-- Топ 10 продавцов с наибольшей выручкой
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;
-- Продавцы, чья выручка ниже средней выручки всех продавцов
WITH avg_income_all AS (
    SELECT AVG(s2.quantity * p2.price) AS global_avg
    FROM sales AS s2
    LEFT JOIN products AS p2 ON s2.product_id = p2.product_id
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales AS s
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING AVG(s.quantity * p.price)
    < (SELECT a.global_avg FROM avg_income_all AS a)
ORDER BY average_income ASC;
-- Выручка по дням недели
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TO_CHAR(s.sale_date, 'Day') AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    EXTRACT(ISODOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'Day')
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;
-- Подсчет покупателей в разрезе возраста
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'unknown'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'unknown'
    END
ORDER BY age_category;
-- Данные по количеству уникальных покупателей и выручке
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;
-- Отчет о покупателях, первая покупка которых была в ходе проведения акций
WITH first_purchases AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.price,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date, s.sales_id
        ) AS rn
    FROM sales AS s
    LEFT JOIN products AS p ON s.product_id = p.product_id
    WHERE p.price = 0
)

SELECT
    fp.sale_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchases AS fp
LEFT JOIN customers AS c ON fp.customer_id = c.customer_id
LEFT JOIN employees AS e ON fp.sales_person_id = e.employee_id
WHERE fp.rn = 1
ORDER BY c.customer_id;
