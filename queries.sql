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
    EXTRACT(DOW FROM s.sale_date), -- возвращаем порядковый номер дня недели
    seller; -- сортируем результат сначала по порядковому номеру дня недели, потом по имени продавца
    