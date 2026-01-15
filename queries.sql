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



SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- объединяем имя и фамилию продавца через пробел с помощью CONCAT
    COUNT(s.sales_id) AS operations, -- считаем количество продаж (строк в таблице sales) для каждого продавца
    FLOOR(SUM(s.quantity * p.price)) AS income -- считаем суммарную выручку как сумму  quantity * price по всем продажам и округляем вниз
FROM 
    employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id -- присоединяем таблицы
    INNER JOIN products p ON s.product_id = p.product_id
GROUP BY 
    e.employee_id, e.first_name, e.last_name -- группируем данные по продавцам
ORDER BY 
    income desc -- сортируем результат по убыванию выручки
LIMIT 10; -- ограничиваем вывод до 10 продавцов



SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- объединяем имя и фамилию продавца через пробел с помощью CONCAT
    FLOOR(AVG(s.quantity * p.price)) AS average_income -- вычисляем среднюю выручку за сделку для каждого продавца и округляем результат
FROM 
    employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id -- присоединяем таблицы черех Иннер, потому что нам нужны только те строки, для которых есть совпадения в обоих таблицах
    INNER JOIN products p ON s.product_id = p.product_id
GROUP BY 
    e.employee_id, e.first_name, e.last_name -- группируем продажи по продавцам
HAVING -- используем HAVING а не where, потому что фильтруем по AVG
    AVG(s.quantity * p.price) < (
        SELECT AVG(s2.quantity * p2.price)
        FROM sales s2
        INNER JOIN products p2 ON s2.product_id = p2.product_id
    )
ORDER BY 
    average_income ASC; -- сортируем по average_income по возрастанию 
    

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller, -- объединяем имя и фамилию продавца в один столбец.
    CASE EXTRACT(DOW FROM s.sale_date)
        WHEN 0 THEN 'sunday'
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
    END AS day_of_week, -- возвращаем название дня недели на английском языке
    FLOOR(SUM(s.quantity * p.price)) AS income -- вычисляем суммарную выручку по каждому продавцу и округляем 
FROM 
     employees e
    INNER JOIN sales s ON e.employee_id = s.sales_person_id
    INNER JOIN products p ON s.product_id = p.product_id
GROUP BY 
     e.employee_id, e.first_name, e.last_name, EXTRACT(DOW FROM s.sale_date) -- группируем данные по продавцу и дню недели
ORDER BY 
    CASE EXTRACT(DOW FROM s.sale_date)
        WHEN 1 THEN 1  -- monday
        WHEN 2 THEN 2  -- tuesday
        WHEN 3 THEN 3  -- wednesday
        WHEN 4 THEN 4  -- thursday
        WHEN 5 THEN 5  -- friday
        WHEN 6 THEN 6  -- saturday
        WHEN 0 THEN 7  -- sunday → last
    END,
    seller; -- сортируем результат сначала по порядковому номеру дня недели, потом по имени продавца
    