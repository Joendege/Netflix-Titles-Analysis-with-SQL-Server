USE Orders


create table [netflix_titles](
	[show_id] varchar(10) primary key, 
	[type] varchar(10), 
	[title] nvarchar(200), 
	[director] varchar(250), 
	[cast] varchar(1000), 
	[country] varchar(150),
	[date_added] varchar(20), 
	[release_year] int, 
	[rating] varchar(10), 
	[duration] varchar(10), 
	[listed_in] varchar(100),
	[description] varchar(500)
	)

SELECT * FROM netflix_titles ORDER BY title DESC

SELECT 
	COLUMN_NAME, 
	DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'netflix_titles'

-- Checking Duplicates

SELECT 
	show_id,
	COUNT(*)
FROM netflix_titles
GROUP BY show_id
HAVING COUNT(*) > 1

SELECT 
	title,
	COUNT(*)
FROM netflix_titles
GROUP BY title
HAVING COUNT(*) > 1

SELECT 
	* 
FROM netflix_titles
WHERE CONCAT(title, type) IN(SELECT 
					CONCAT(title, type)
				FROM netflix_titles
				GROUP BY title, type
				HAVING COUNT(*) > 1)
ORDER BY title 

SELECT 
	* 
INTO netflix_data
FROM
	(SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY title, type ORDER BY show_id) AS rw_num
	FROM netflix_titles) a
WHERE rw_num = 1

SELECT * FROM netflix_data

--Directors
SELECT 
	show_id, 
	TRIM(value) AS director
INTO netflix_directors
FROM netflix_data
CROSS APPLY string_split(director, ',')

--Country
SELECT 
	show_id, 
	TRIM(value) AS country 
INTO netflix_country
FROM netflix_data
CROSS APPLY string_split(country, ',')

SELECT * FROM netflix_country

--Cast
SELECT 
	show_id,
	TRIM(value) AS cast
INTO netflix_cast
FROM netflix_data
CROSS APPLY string_split(cast, ',')

SELECT * FROM netflix_cast

--listed_in

SELECT 
	show_id, 
	TRIM(value) AS listed_in
INTO netflix_listed_in
FROM netflix_data
CROSS APPLY string_split(listed_in, ',')

SELECT * FROM netflix_listed_in

--Populating missing values in country and duration columns
--Country
INSERT INTO netflix_country
SELECT 
	show_id, m.country
FROM netflix_data nd
JOIN (SELECT 
		director, country
	  FROM netflix_country nc
	  JOIN netflix_directors nd
      ON nc.show_id = nd.show_id
	  GROUP BY director, country) m
ON nd.director = m.director
WHERE nd.country IS NULL


--Duration
SELECT * FROM netflix_data WHERE duration IS NULL

SELECT 
	show_id, 
	type, 
	title, 
	CAST(date_added AS date) AS date_added, 
	release_year, 
	rating,
	CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration,
	description
INTO netflix_final
FROM netflix_data

SELECT * FROM netflix_final WHERE date_added IS NULL

--Data Analysis

/* For each director count the number of Movies and TV Shows created by them in seperate columns
for directors who have created both Movies and TV Shows
*/

SELECT 
	 nd.director,
	 COUNT(DISTINCT CASE WHEN nf.type = 'Movie' THEN nf.show_id END) AS total_movies,
	 COUNT(DISTINCT CASE WHEN nf.type = 'TV Show' THEN nf.show_id END) AS total_tv_shows
FROM netflix_final nf
JOIN netflix_directors nd ON nf.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT nf.type) > 1

--Which country has high numbers of comedy movies
SELECT TOP 1
	nc.country, COUNT(DISTINCT nl.show_id) no_of_movies
FROM netflix_listed_in nl
JOIN netflix_country nc ON nl.show_id = nc.show_id
JOIN netflix_final nf ON nl.show_id = nf.show_id
WHERE nl.listed_in = 'Comedies' AND nf.type = 'Movie'
GROUP BY nc.country
ORDER BY no_of_movies DESC

--For each year(as per date added to netflix), which director has maximum number of movie released

SELECT 
	b.director, b.year, b.no_of_movies
FROM
(SELECT 
	a.*,
	ROW_NUMBER() OVER(PARTITION BY a.year ORDER BY a.no_of_movies DESC, a.director) AS rw_num
FROM 
	(SELECT
		nd.director,
		YEAR(nf.date_added) year,
		COUNT(nf.show_id) no_of_movies
	FROM netflix_final nf
	JOIN netflix_directors nd ON nf.show_id = nd.show_id
	WHERE nf.type = 'Movie' AND YEAR(nf.date_added) = nf.release_year
	GROUP BY YEAR(nf.date_added), nd.director) a) b
WHERE b.rw_num = 1


--What is the average duration of movies in each genre
SELECT 
	nl.listed_in, AVG(CAST(REPLACE(nf.duration, ' min', '') AS INT)) avg_duration 
FROM netflix_final nf
JOIN netflix_listed_in nl ON nl.show_id = nf.show_id
WHERE nf.type = 'Movie'	
GROUP BY nl.listed_in
ORDER BY avg_duration DESC

/*Find the list of directors who have created both horror and comedy movies, 
Display director names along with the number of horrors and comedy movies */

SELECT 
	nd.director, 
	COUNT(DISTINCT CASE WHEN nl.listed_in = 'Horror Movies' THEN nf.show_id END) no_horror_movies,
	COUNT(DISTINCT CASE WHEN nl.listed_in = 'Comedies' THEN nf.show_id END) no_comedy_movies
FROM netflix_final nf
JOIN netflix_listed_in nl ON nf.show_id = nl.show_id
JOIN netflix_directors nd ON nd.show_id = nf.show_id
WHERE nf.type= 'Movie' AND nl.listed_in IN('Horror Movies', 'Comedies')
GROUP BY nd.director
HAVING COUNT(DISTINCT nl.listed_in) = 2
ORDER BY nd.director









