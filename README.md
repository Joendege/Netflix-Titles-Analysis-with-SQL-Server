# Netflix Titles Analysis Report

## Table of Contents

- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Data Cleaning and Preparation](#data-cleaning-and-preparation)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis](#data-analysis)
- [Recommedations](#recommedations)
- [Results and Findings](#results-and-findings)
- [Limitations](#limitations)
- [References](#references)

### Project Overview
This data analysis project aims at providing insights about netflix movies and TV shows added to the netflix website over a given period of time. Through analyzing this data we get a deeper understanding of the various titles that were added in the netflix website. We also get a clear picture of appearance of various casts in different titles, genres and also directors managing different titles and genres in respect to country and ratings of the same titles.

![no_movies_tvshows_per_director](https://github.com/Joendege/Netflix-Titles-Analysis-with-SQL-Server/assets/123901910/73916053-1439-4673-bfea-8c67f70e9e92)

![director_with_max_movies_released_based_on_year(date_added)](https://github.com/Joendege/Netflix-Titles-Analysis-with-SQL-Server/assets/123901910/9c5347e3-291a-4485-8299-b9c982cbff6d)

![avg_duration_of_movie_per_genre](https://github.com/Joendege/Netflix-Titles-Analysis-with-SQL-Server/assets/123901910/2c118411-396f-4e9d-a9c1-0c70f249c30b)

![directors_with_both_horr_comedy_movies](https://github.com/Joendege/Netflix-Titles-Analysis-with-SQL-Server/assets/123901910/a64d64ed-0105-4a23-a32e-12e5ee2eba68)

### Data Sources
The primary data source used for this analysis is "netflix_titles.csv" file containing details of each and every titles available at the neflix website.

### Tools
1. Jupyter Notebook - Data Inspection and Loading dataframe to a table in Ms SQL Server. [Download Here](www.anaconda.com/)
2. Ms SQL Server- Data Cleaning, Formatting and Analysis [Download Here](www.microsoft.com)


### Data Cleaning and Preparation
In the initial data preparation phase we performed the following tasks:
1. Data Loading and Inspection
2. Removing Duplicates
3. Generating new tables from the original table i.e directors, genres, cast, country
4. Populating mising values in country and duration columns
5. Data formatting and cleaning


### Exploratory Data Analysis
EDA involved exploring the sales data to answer key questions, such as:
1. How many total movies and TV shows were created by directors who created both types?
2. Which country has the highest number of comedy movies?
3. Which director has maximum number of movies released based on the year as per date added?
4. Who are the directors that have created both horror and comedies movies, and the total number of the movies created?
5. What is the average duration for movies in each genre?

### Data Analysis
Some of SQL Queries i used are:
``` SQL
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
```
``` SQL
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
```
``` SQL
--Which country has high numbers of comedy movies
SELECT TOP 1
	nc.country, COUNT(DISTINCT nl.show_id) no_of_movies
FROM netflix_listed_in nl
JOIN netflix_country nc ON nl.show_id = nc.show_id
JOIN netflix_final nf ON nl.show_id = nf.show_id
WHERE nl.listed_in = 'Comedies' AND nf.type = 'Movie'
GROUP BY nc.country
ORDER BY no_of_movies DESC
```
``` SQL
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
```
``` SQL
--What is the average duration of movies in each genre
SELECT 
	nl.listed_in, AVG(CAST(REPLACE(nf.duration, ' min', '') AS INT)) avg_duration 
FROM netflix_final nf
JOIN netflix_listed_in nl ON nl.show_id = nf.show_id
WHERE nf.type = 'Movie'	
GROUP BY nl.listed_in
ORDER BY avg_duration DESC
```
``` SQL
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
```

### Recommedations 
Based on the analysis, we recommed the following actions:
1. There should be continued investment towards the popular genres
2. Continued relationship fostering between sucessful directors and casts
3. Investing in niche genres to attract broader viewership

### Results and Findings
The analysis results are summarized as follows:
1. The average duration for most movies is approximate more that 60mins
2. Most popular directors produced most sucessfull titles.

### Limitations
I had to remove split the directors, cast, country and genre column to individual entry, then populate the country table with values of country from which the director was reponsible for the title to the values that were Null

### References
- [Stack Overflow](www.stack-overflow.com)
- [W3 Schools](www.w3schools.com)
