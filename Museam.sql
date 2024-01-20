#Fetch all the paintings which are not displayed on any museums?
select work_id from work
where work_id not in (select work_id from museum);
#Are there museuems without any paintings?
select museum_id from museum
where museum_id not in (select museum_id from work);
#How many paintings have an asking price of more than their regular price? 
select work_id from product_size
where sale_price>regular_price;
#Identify the paintings whose asking price is less than 50% of its regular price
select work_id from product_size
where sale_price<0.5*regular_price;
#Which canva size costs the most?
select * from product_size p
join canvas_size c on p.size_id=c.size_id
order by sale_price desc
limit 1;
#Identify the museums with invalid city information in the given dataset
SELECT * FROM museum
WHERE city REGEXP '^[0-9]';
#Museum_Hours table has 1 invalid entry. Identify it and remove it.
SELECT *
FROM Museum_Hours
WHERE NOT (open REGEXP '^[0-9]{1,2}:[0-9]{2} [AP]M$')
   OR NOT (CLOSE REGEXP '^[0-9]{1,2}:[0-9]{2} [AP]M$');
#Fetch the top 10 most famous painting subject
select subject,count(work_id) n from subject
group by subject
order by n desc
limit 10;
#Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select museum_id from museum_hours
where day='sunday' and museum_id in (select museum_id from museum_hours 
where day='Monday');
#How many museums are open every single day?
select museum_id,count(distinct day) as nod from museum_hours
group by museum_id
having nod=7;
#Which are the top 5 most popular museum?
select museum_id,count(work_id) as c from work
group by museum_id
order by c desc
limit 5;
#Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select artist_id,count(work_id) as c from work
group by artist_id
order by c desc
limit 5;
#Display the 3 least popular canva sizes
select size_id,count(work_id) as c from product_size
group by size_id
order by c
limit 3;
select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;
#Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
with cte as (SELECT 
    museum_id,day,
    STR_TO_DATE(REPLACE(open, ':AM', ' AM'), '%h:%i %p') AS opening_time, 
    STR_TO_DATE(REPLACE(CLOSE, ':PM', ' PM'), '%h:%i %p') AS closing_time,
    TIMEDIFF(
        STR_TO_DATE(REPLACE(CLOSE, ':PM', ' PM'), '%h:%i %p'),
        STR_TO_DATE(REPLACE(open, ':AM', ' AM'), '%h:%i %p')
    ) AS time_difference
FROM 
    museum_hours)
select museum_id, day,time_difference from cte

order by time_difference desc
limit 1;
#Which museum has the most no of most popular painting style?
with cte as (select style
 from work
group by style
order by count(work_id) desc
limit 1),
cte1 as (select museum_id,w.style,count(work_id) as n from work w
join cte a on a.style=w.style
 group by museum_id,w.style)
select  * from cte1
order by n desc
limit 1;
#Identify the artists whose paintings are displayed in multiple countries
select artist_id,count( distinct country) as cn  from work w
join museum m on m.museum_id=w.museum_id
group by artist_id
having cn>1
order by cn desc;
#Display the country and the city with most no of museums. 
WITH CountryMuseums AS (
    SELECT country, COUNT(museum_id) AS num_museums_country
    FROM museum
    GROUP BY country
    ORDER BY num_museums_country DESC
    LIMIT 1
),
CityMuseums AS (
    SELECT city, COUNT(museum_id) AS num_museums_city
    FROM museum
    GROUP BY city
    ORDER BY num_museums_city DESC
    LIMIT 1
)
SELECT cm.country, cm.num_museums_country, ctm.city, ctm.num_museums_city
FROM CountryMuseums cm, CityMuseums ctm;

# Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, sale_price, painting name, museum name, museum city and canvas label
with cte as(select full_name as artist_name ,m.name as museam_name,w.name as painting_name ,sale_price,
 rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
 from product_size ps
join work w on w.work_id=ps.work_id
join artist a on a.artist_id=w.artist_id
join museum m on m.museum_id=w.museum_id)
select * from cte where rnk=1 or rnk_asc=1;
#Which country has the 5th highest no of paintings?
with cte as (select m.country,count(work_id),dense_rank() over(order by count(work_id) desc) as rn from work w
join museum m on m.museum_id=w.museum_id
group by m.country)
select * from cte
where rn=5;
#Which are the 3 most popular and 3 least popular painting styles?
with cte as (select style,count(work_id),rank() over(order by count(work_id) desc) as trnk,
rank() over(order by count(work_id) ) as brnk from work 
group by style)
select * from cte 
where trnk<4 or brnk<4;
# Which artist has the most no of Portraits painting. Display artist name, no of paintings and the artist nationality.
select a.artist_id,a.nationality,count(w.work_id) as c from work w
join artist a on a.artist_id=w.artist_id
join subject s on w.work_id=s.work_id
where s.subject='portraits'
group by a.artist_id,a.nationality
order by c desc
