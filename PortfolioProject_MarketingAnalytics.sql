-- Выбор данных по таблице dbo.customer_reviews
-- Очищистка ReviewText от двойных пробелов для единообразия данных

SELECT
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	REPLACE(ReviewText, '  ', ' ') AS ReviewText
FROM 
	dbo.customer_reviews
	


-- Выбор данных по таблице dbo.engagement_data
-- Преобразование к единому виду значений ContentType, преобразование в человекочитаемый вид EngagementDate, разделение ViewsClicksCombined на Views и Clicks
-- Фильтрация записей, исключая новостные рассылки

SELECT
	EngagementID,
	CampaignID,
	ContentID,
	ProductID,
	ContentType,
	UPPER(REPLACE(ContentType, 'Socialmedia', 'SOCIALMEDIA')),
	LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,
	RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,
	Likes,
	FORMAT(CONVERT(DATE,EngagementDate), 'dd.MM.yyyy') AS EngagmentDate
FROM 
	dbo.engagement_data
WHERE ContentType != 'NewsLetter'



-- Выбор данных по таблице 
-- Категоризация числовых значений Price к текстовым для упрощения анализа

SELECT ProductID, ProductName, Price,

	CASE 
		WHEN Price < 50 THEN 'Low'
		WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
		ELSE 'High'
	END AS PriceCategory

FROM dbo.products


-- Объединение данных о клиентах с их географическим положением

SELECT  
	c.CustomerID, 
	c.CustomerName, 
	c.Email, 
	c.Gender, 
	c.Age, 
	g.Country, 
	g.City
FROM 
	dbo.customers c
LEFT JOIN 
	dbo.geography g ON c.GeographyID = g.GeographyID



-- Поиск дубликатов в dbo.customer_journey

WITH DuplicateRecords AS(
	SELECT
		JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		Stage,
		Action,
		Duration,
		ROW_NUMBER() OVER (
			PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
			ORDER BY JourneyID
		) AS row_num
	FROM 
		dbo.customer_journey
)

-- Очистка данных dbo.customer_journey (пробелы, регистр)
-- Разделение комбинированных полей
-- Категоризация числовых значений
-- Обработка NULL-значений с заменой на средние
-- Удаление дубликатов

SELECT * 
FROM DuplicateRecords
WHERE row_num > 1
ORDER BY JourneyID;


SELECT
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	Stage,
	Action,
	COALESCE(Duration, avg_duration) AS Duration
FROM
	(
		SELECT 
			JourneyID,
			CustomerID,
			ProductID,
			VisitDate,
			UPPER(Stage) AS Stage,
			Action,
			AVG(Duration) OVER (PARTITION BY visitDate) AS avg_duration,
			ROW_NUMBER()  OVER(
				PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
				ORDER BY JourneyID
			) AS row_num
		FROM
			dbo.customer_journey
	) AS subquery
WHERE
	row_num = 1
