--Самые богатые клиенты и их характеристика
SELECT balance, marital, age, job DENSE_RANK() OVER(ORDER BY balance DESC) AS "rank"
FROM default.bank 
LIMIT 20
;

--Самые богатые люди по каждой профессии
SELECT *
FROM (
	SELECT age, job, marital, balance, RANK() OVER(PARTITION BY job ORDER BY balance DESC) AS "rank by job"
	FROM default.bank 
)
WHERE "rank by job" <=3
ORDER BY job, "rank by job"
;

--Средний баланс и описание возраста по образованию
SELECT education, ROUND(AVG(balance), 2) AS "average balance", 
		MIN(age) AS "min age", MAX(age) AS "max age"
FROM default.bank
GROUP BY education
ORDER BY ROUND(AVG(balance), 2) DESC
;

--Конверсия по профессиям
SELECT job,
	COUNTIf(deposit = 'yes') AS total_accepted,
	COUNT(*) AS total_clients,
	ROUND( (COUNTIf(deposit = 'yes') / COUNT(*)) * 100, 2) AS perc_conv
FROM default.bank
GROUP BY job
ORDER BY perc_conv DESC
;

--Перспективные для открытия вклада
SELECT age, job, balance, RANK() OVER(ORDER BY balance DESC) AS rank
FROM default.bank 
WHERE deposit = 'no'
LIMIT 20
;

--Аномально высокий баланс по профессии
SELECT age, job, balance, ROUND(ABS(balance - AVG(balance) OVER(PARTITION BY job)), 2) AS "deviance (money)",
	ROUND( (balance / AVG(balance) OVER(PARTITION BY job)) * 100, 2) AS "deviance (perc)",
	ROUND(AVG(balance) OVER(PARTITION BY job), 2) AS "mean"
FROM default.bank 
ORDER BY "deviance (perc)" DESC
LIMIT 30
;

--Успешность маркетинга по месяцам
SELECT month, SUM(campaign) AS "total contacts", SUMIf(campaign, deposit='yes') AS "succesfull contacts",
	ROUND((SUMIf(campaign, deposit='yes') / SUM(campaign)) * 100, 2) AS "convertion by month"
FROM default.bank 
GROUP BY month
ORDER BY "convertion by month" DESC
;

--Поиск 'горячих' клиентов: пока не согласились на вклад, имеют ипотеку и не имеют кредита, входят в топ 10 баланса по профессии
SELECT * FROM (
	SELECT age, balance, job, ROUND( (RANK() OVER(ORDER BY balance DESC) / COUNT(*) OVER()) * 100, 3) AS "cume dist by prof",
		RANK() OVER(PARTITION BY job ORDER BY balance DESC) AS "rank by profession"
	FROM default.bank 
	WHERE deposit = 'no' AND housing = 'yes' AND loan = 'no'
)
WHERE "cume dist by prof" <= 10
ORDER BY balance DESC
;

--Расчет конверсии (%) и цены конверсии в разрезе количества контактов с клиентов (для каждого значения campaign больше 10 клиентов)
SELECT campaign, ROUND((COUNTIf(deposit='yes') / COUNT(*)) * 100, 2) AS "convertion",
	ROUND(COUNT(*) / COUNTIf(deposit='yes'), 2) AS "convertion cost"
FROM default.bank 
GROUP BY campaign
HAVING COUNT(*) > 10
ORDER BY campaign DESC
;

--Конверсия в зависимости от предыдущего опыта
SELECT poutcome AS "previous experience", ROUND((COUNTIf(deposit = 'yes') / COUNT(*)) * 100, 2) AS "convertion"
FROM default.bank
GROUP BY poutcome
ORDER BY convertion DESC
;


--Конверсия по месяцам в зависимости от семейного положения
SELECT month, ROUND((COUNTIf(deposit='yes' AND marital='divorced') / COUNTIf(marital='divorced')) * 100, 2) AS "divorced",
		ROUND((COUNTIf(deposit='yes' AND marital='single') / COUNTIf(marital='single')) * 100, 2) AS "single",
		ROUND((COUNTIf(deposit='yes' AND marital='married') / COUNTIf(marital='married')) * 100, 2) AS "married"
FROM default.bank 
GROUP BY month
ORDER BY month
;

--Скользящее среднее конверсии и длительности звонков по дням месяца 
SELECT day, convertion, ROUND(AVG(convertion) OVER(ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS "mov avg 3 conv",
	ROUND(AVG(duration) OVER(ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS "mov avg 3 duration"
FROM (
	SELECT day, ROUND((COUNTIf(deposit='yes') / COUNT(*)) * 100, 2) AS "convertion", AVG(duration) AS duration
	FROM default.bank
	GROUP BY day
	ORDER BY day
)
;

--Анализ конверсии в зависимости от длительности звонка
SELECT
	CASE
		WHEN duration BETWEEN 0 AND 120 THEN 'short (1-2)'
		WHEN duration BETWEEN 120 AND 300 THEN 'middle (2-5)'
		WHEN duration BETWEEN 300 AND 600 THEN 'upper middle (5-10)'
		WHEN duration BETWEEN 600 AND 1200 THEN 'long (10-20)'
		ELSE 'very long (20+)'
	END AS category,
	ROUND((COUNTIf(deposit='yes') / COUNT(*)) * 100, 2) AS "conv",
	COUNT() AS "quantity",
	ROUND((COUNT() / SUM("quantity") OVER()) * 100, 2) AS "percentage of category",
	COUNTIf(deposit='yes') AS "success by category",
	ROUND(("success by category" / SUM("success by category") OVER()) * 100, 2) AS "perc of success by category"
FROM default.bank 
GROUP BY category
ORDER BY conv DESC
;


--Кросс анализ признаков
SELECT housing, loan, marital, ROUND((COUNTIf(deposit='yes') / COUNT(*)) * 100, 2) AS "convertion"
FROM default.bank
GROUP BY housing, loan, marital
ORDER BY convertion DESC
