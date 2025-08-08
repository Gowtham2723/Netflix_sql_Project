create database netflixdb;
use netflixdb;
CREATE TABLE Netflix_titles (
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
select * 
from netflixdb.netflix_titles;

-- Business Problems and Solutions

-- Task-1
-- Count the Number of Movies vs TV Shows
select type,
count(*) as total
from netflix_titles
group by type;

-- Task-2
-- Find the Most Common Rating for Movies and TV Shows
with Ratingcounts as(
select type,rating,count(*) as rating_count
from netflix_titles
group by type,rating
 ),
 Rankedratings as(
 select type,rating,rating_count,
 rank() over(partition by type  order by rating_count desc) as rnk
 from ratingcounts
 )
 select type,rating as most_common_rating
 from rankedratings
 where rnk = 1;
 
 -- Task-3
 -- List All Movies Released in a Specific Year (e.g., 2020)
 select * from netflix_titles
 where release_year = 2020;
 
 -- Task-4
 -- Find the Top 5 Countries with the Most Content on Netflix
 WITH RECURSIVE split_countries AS (
  -- Base case: get the first country and remaining countries
  SELECT 
   show_id,
    TRIM(SUBSTRING_INDEX(country, ',', 1)) AS country,
    SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2) AS remaining
  FROM netflix_titles
  WHERE country IS NOT NULL

  UNION ALL

  -- Recursive case: continue splitting the remaining string
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS country,
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2) AS remaining
  FROM split_countries
  WHERE remaining IS NOT NULL AND remaining != ''
)
-- Final aggregation
SELECT 
  country,
  COUNT(*) AS total_content
FROM split_countries
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_content DESC
limit 5;
/*explanation
| Step                           | What it does                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------ |
| `WITH RECURSIVE`               | Creates a temporary recursive table to split country strings                               |
| `SUBSTRING_INDEX(..., ',', 1)` | Gets the **first country** in the string                                                   |
| `SUBSTRING(... + 2)`           | Extracts the **rest of the string** after the first country (skipping the comma and space) |
| `UNION ALL`                    | Continues the process recursively until no comma is left                                   |
| `GROUP BY country`             | Groups all occurrences of a country (even from multi-country rows)                         |
| `ORDER BY ... DESC LIMIT 5`    | Sorts and picks top 5 most frequent countries        
*/                                      

-- Task -5
-- Identify the Longest Movie
-- identify the longest tv show

SELECT title,duration,release_year,country
from netflix_titles
where type = 'Movie'
and duration like '%min'
order by
 cast(substring_index(duration, '',1) as unsigned) desc
 limit 1;
 -- longest tv show
 SELECT title,duration,release_year,country
from netflix_titles
where type = 'tv show'
and duration like '%season%'
order by
 cast(substring_index(duration, '',1) as unsigned) desc
 limit 1;
-- explanation
/* 
 | Clause                              | What it does                                               |
| ----------------------------------- | ---------------------------------------------------------- |
| `type = 'TV Show'`                  | Only TV shows                                              |
| `duration LIKE '%Season%'`          | Filters entries with "1 Season", "3 Seasons", etc.         |
| `SUBSTRING_INDEX(duration, ' ', 1)` | Gets just the number part (e.g., `'6'` from `'6 Seasons'`) |
| `CAST(... AS UNSIGNED)`             | Converts it to a number so we can sort numerically         |
| `ORDER BY ... DESC LIMIT 1`         | Gets the show with the most seasons                        |
*/
 
 -- Task-6
 -- Find Content Added in the Last 5 Years
 SELECT title, type, date_added 
FROM netflix_titles 
WHERE date_added >= CURDATE() - INTERVAL 5 YEAR;

 -- Task - 7
 -- a.Find All Movies/TV Shows by Director 'Rajiv Chilaka'
 -- b.and also find any other director worked with rajiv chilaka
 -- a
 select title,type,director,release_year,country
 from netflix_titles
 where director = 'Rajiv chilaka';
 
 -- b.
 -- with normal string function
SELECT DISTINCT director,title,release_year
FROM netflix_titles
WHERE title IN (
    SELECT title
    FROM netflix_titles
    WHERE director LIKE '%Rajiv chilaka%'
);

-- with recursive ctes
WITH RECURSIVE split_directors AS (
  -- Base case: split the first director
  SELECT 
    show_id,
    title,
    type,
    release_year,
    TRIM(SUBSTRING_INDEX(director, ',', 1)) AS director,
    SUBSTRING(director, LENGTH(SUBSTRING_INDEX(director, ',', 1)) + 2) AS remaining
  FROM netflix_titles
  WHERE director IS NOT NULL
  UNION ALL
 -- Recursive case: continue splitting the remaining directors
  SELECT 
    show_id,
    title,
    type,
    release_year,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS director,
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2) AS remaining
  FROM split_directors
  WHERE remaining IS NOT NULL AND remaining != ''
)
-- Final filtering
SELECT 
  show_id,
  title,
  type,
  release_year,
  director
FROM split_directors
WHERE director in ('Rajveer Singh Maan' and 'Harpeet Singh')
ORDER BY release_year DESC;

-- Task-8
-- Count the Number of Content Items in Each Genre
WITH RECURSIVE split_genres AS (
  -- Base case
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
    SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS remaining
  FROM netflix_titles
  WHERE listed_in IS NOT NULL

  UNION ALL

  -- Recursive case
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
  FROM split_genres
  WHERE remaining IS NOT NULL AND remaining != ''
)

-- Final aggregation
SELECT 
  genre,
  COUNT(*) AS total_titles
FROM split_genres
WHERE genre IS NOT NULL
GROUP BY genre
ORDER BY total_titles DESC;

-- Task - 10
-- Find each year and the average numbers of content release in India on netflix.
-- using round fuction
select country,release_year,count(show_id) AS total_release,
round(
count(show_id) * 100.0/
(select count(show_id) 
from netflix_titles
where country = 'India'),2
) as avg_release
from netflix_titles
where country = 'India'
group by country,release_year
order by avg_release desc
limit 10;

-- Task -11
-- List All Movies that are Documentaries
SELECT distinct listed_in
FROM netflix_titles
WHERE listed_in like '%Documentaries%';

-- Task-12
-- Find All Content Without a Director
select * from netflix_titles
where director is null;

-- Task-13
-- Find the Top 10 Actors Who Have Appeared in the Highest
-- Number of Movies Produced in India
WITH RECURSIVE split_casts AS (
  -- Anchor: take the first actor from the casts list
  SELECT 
    show_id,
    title,
    TRIM(SUBSTRING_INDEX(casts, ',', 1)) AS actor,
    SUBSTRING(casts, LENGTH(SUBSTRING_INDEX(casts, ',', 1)) + 2) AS remaining
  FROM netflix_titles
  WHERE type = 'Movie'
    AND country = 'India'
    AND casts IS NOT NULL

  UNION ALL

  -- Recursive part: continue splitting remaining casts list
  SELECT 
    show_id,
    title,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2)
  FROM split_casts
  WHERE remaining IS NOT NULL AND remaining != ''
)

-- Final: group and count appearances
SELECT 
  actor,
  COUNT(*) AS movie_count
FROM split_casts
GROUP BY actor
ORDER BY movie_count DESC
LIMIT 10;

-- Task-14
-- Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
SELECT 
    category,
    COUNT(*) AS content_count
FROM (
    SELECT 
        CASE 
            WHEN LOWER(description) LIKE '%kill%' 
              OR LOWER(description) LIKE '%violence%' 
            THEN 'Violent'
            WHEN LOWER(description) LIKE '%murder%' 
              OR LOWER(description) LIKE '%crime%' 
            THEN 'Crime'
            WHEN LOWER(description) LIKE '%drugs%' 
            THEN 'Drugs Related'
            ELSE 'Neutral'
        END AS category
    FROM netflix_titles
    WHERE description IS NOT NULL
) AS categorized_content
GROUP BY category;









