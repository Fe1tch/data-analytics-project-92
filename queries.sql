--считает общее количество клиентов
SELECT COUNT(*) as customers_count
FROM customers;
--Топ 10 продавцов с наибольшей выручкой
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM employees AS e
INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;
--Продавцы, чья выручка ниже средней выручки всех продавцов
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM employees AS e
INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id
HAVING AVG(s.quantity * p.price) < (
    SELECT AVG(s2.quantity * p2.price)
    FROM sales AS s2
    INNER JOIN products AS p2 ON s2.product_id = p2.product_id)
ORDER BY average_income ASC;
-- Выручка по дням
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    CASE EXTRACT(DOW FROM s.sale_date)
        WHEN 0 THEN 'sunday'
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
    END AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM employees AS e
INNER JOIN sales AS s ON e.employee_id = s.sales_person_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    EXTRACT(DOW FROM s.sale_date)
ORDER BY
    CASE EXTRACT(DOW FROM s.sale_date)
        WHEN 1 THEN 1
        WHEN 2 THEN 2
        WHEN 3 THEN 3
        WHEN 4 THEN 4
        WHEN 5 THEN 5
        WHEN 6 THEN 6
        WHEN 0 THEN 7
    END,
    seller;
--подсчет покупателей в разрезе возраста
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'unknown'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers AS c
WHERE age >= 16
GROUP BY
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'unknown'
    END
ORDER BY age_category;
-- данные по количеству уникальных покупателей и выручке
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY TO_CHAR(s.sale_date, 'YYYY-MM');
--отчет о покупателях, первая покупка которых была 
--в ходе проведения акций
WITH first_purchases AS 
(
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
    INNER JOIN products AS p ON s.product_id = p.product_id
)
SELECT
    fp.sale_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchases AS fp
INNER JOIN customers AS c ON fp.customer_id = c.customer_id
INNER JOIN employees AS e ON fp.sales_person_id = e.employee_id
WHERE
    fp.rn = 1
    AND fp.price = 0
ORDER BY c.customer_id;