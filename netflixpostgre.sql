-- Create database
CREATE DATABASE netflix_project;

-- Connect to it manually in your client/pgAdmin. No 'USE' in PostgreSQL.

-- Drop table if exists
DROP TABLE IF EXISTS netflix_data;

-- Create table
CREATE TABLE netflix_data (
    show_id         VARCHAR(100),
    type_           VARCHAR(100),
    title           VARCHAR(250),
    director        VARCHAR(100),
    cast_           VARCHAR(500),
    country         VARCHAR(100),
    date_added      VARCHAR(150),
    release_year    INT,
    rating          VARCHAR(100),
    duration        VARCHAR(100),
    listed_in       VARCHAR(200),
    description_    VARCHAR(1000)
);
ALTER TABLE netflix_data ALTER COLUMN cast_ TYPE TEXT;
ALTER TABLE netflix_data ALTER COLUMN director TYPE TEXT;
ALTER TABLE netflix_data ALTER COLUMN country TYPE TEXT;
-- Count Movies vs TV Shows
SELECT type_, COUNT(show_id) 
FROM netflix_data 
GROUP BY type_;

-- Find most common ratings for movies and TV shows
WITH cte AS (
    SELECT type_, rating, COUNT(*) AS net_count 
    FROM netflix_data 
    GROUP BY type_, rating
)
SELECT type_, rating 
FROM (
    SELECT *, RANK() OVER (PARTITION BY type_ ORDER BY net_count DESC) AS ranks 
    FROM cte
) AS ranked_data
WHERE ranks = 1;

-- List all movies released in 2020
SELECT show_id, title 
FROM netflix_data 
WHERE release_year = 2020 AND type_ = 'Movie';

-- Top 5 countries with most content
SELECT unnest(string_to_array(country,', ')) as country, COUNT(show_id) 
FROM netflix_data 
GROUP BY country 
ORDER BY COUNT(show_id) DESC 
LIMIT 5;


-- Identify the longest movie
SELECT title, duration 
FROM netflix_data 
WHERE type_ = 'Movie' and title!='nan' and duration!='nan'
ORDER BY CAST(SPLIT_PART(duration, ' ', 1) AS INT) DESC 
LIMIT 1;

-- Content added in last 5 year

SELECT show_id, title, type_, release_year, date_added 
FROM netflix_data
where TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years' ;

-- All content by director 'Rajiv Chilaka'
SELECT title, type_, director 
FROM netflix_data 
WHERE director ILIKE '%Rajiv Chilaka';

-- TV shows with more than 5 seasons
SELECT title, duration, type_ 
FROM netflix_data 
WHERE type_ != 'Movie' 
AND CAST(SPLIT_PART(duration, ' ', 1) AS INT) > 5;

-- Top 5 years with highest avg content release by India
SELECT *, total_release * 100.0 / (SELECT COUNT(*) FROM netflix_data WHERE country = 'India') AS average
FROM (
    SELECT EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS year_, COUNT(show_id) AS total_release 
    FROM netflix_data 
    WHERE country = 'India' 
    GROUP BY year_
) AS valued 
ORDER BY total_release DESC 
LIMIT 5;

-- Content without a director
SELECT * FROM netflix_data 
WHERE director IS NULL OR director = '';

-- Movies that are documentaries
SELECT title, listed_in 
FROM netflix_data 
WHERE listed_in ILIKE '%Documentaries%';

-- Movies with Salman Khan in the last 10 years
SELECT * 
FROM netflix_data 
WHERE cast_ ILIKE '%Salman Khan%' 
AND EXTRACT(YEAR FROM CURRENT_DATE) - release_year <= 10;

-- Content with violence or kill keywords
SELECT category, COUNT(*) 
FROM (
    SELECT title,
           CASE 
               WHEN description_ ILIKE '%kill%' OR description_ ILIKE '%violence%' THEN 'Bad'
               ELSE 'Good'
           END AS category
    FROM netflix_data
) AS new_data
GROUP BY category;
-- Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
select actor,count(actor) from(
select show_id,unnest(string_to_array(cast_,',')) as actor from netflix_data
where country ilike '%India') as new_data
group by 1 order by 2 desc
limit 10
--Count the Number of Content Items in Each Genre
select distinct genre,count(genre) from(
select title,unnest(string_to_array(listed_in,',')) as genre from netflix_data)
as genre_data
group by 1