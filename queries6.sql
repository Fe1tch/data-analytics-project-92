SELECT
  case -- задаем условия по возрасту
    WHEN age BETWEEN 16 AND 25 THEN '16-25'
    WHEN age BETWEEN 26 AND 40 THEN '26-40'
    WHEN age > 40 THEN '40+'
  END AS age_category,
  COUNT(*) AS age_count -- считаем количество покупателей в каждой группе
FROM customers
WHERE age >= 16
GROUP BY 1
ORDER BY 1;

SELECT
  TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month, -- преобразуем дату в нужный вид
  COUNT(DISTINCT s.customer_id) AS total_customers, -- считаем уникальных покупателей за каждый месяц
  FLOOR(SUM(s.quantity * p.price)) AS income -- считаем выручку и округляем
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;



WITH first_purchases AS ( -- создаем подзапрос
  SELECT
    s.customer_id,
    s.sale_date,
    s.sales_person_id,
    p.price,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date, s.sales_id) AS rn -- делим все строки на группы по каждому покупателю и присваиваем номер 1 самой ранней покупке каждого покупателя
  FROM sales s
  JOIN products p ON s.product_id = p.product_id
)
SELECT -- основной запрос
  CONCAT(c.first_name, ' ', c.last_name) AS customer,
  fp.sale_date,
  CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_purchases fp
JOIN customers c ON fp.customer_id = c.customer_id
JOIN employees e ON fp.sales_person_id = e.employee_id
WHERE fp.rn = 1                -- оставляем только первые покупки каждого покупателя
  AND fp.price = 0            -- и среди них только акционные
ORDER BY c.customer_id;
