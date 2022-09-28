----------------------------------------------------------------------------------------------------------------
--rent
--rent price over years
WITH table_2020 AS (
	SELECT borough, round(AVG(rent_median_asking_price),2) AS avg_2020, 
					round(MIN(rent_median_asking_price),2) AS min_2020, 
					round(MAX(rent_median_asking_price),2) AS max_2020
	FROM rent_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2020%'
	AND rent_median_asking_price  IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough
), table_2021 AS
	(SELECT borough, round(AVG(rent_median_asking_price),2) AS avg_2021, 
					round(MIN(rent_median_asking_price),2) AS min_2021, 
					round(MAX(rent_median_asking_price),2) AS max_2021
	FROM rent_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2021%'
	AND rent_median_asking_price IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough
), table_2022 AS
	(SELECT borough, round(AVG(rent_median_asking_price),2) AS avg_2022, 
					round(MIN(rent_median_asking_price),2) AS min_2022, 
					round(MAX(rent_median_asking_price),2) AS max_2022
	FROM rent_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2022%'
	AND rent_median_asking_price IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough)
SELECT *
FROM table_2020
LEFT JOIN table_2021
USING (borough)
LEFT JOIN table_2022
USING (borough)

--price by month in each borough
SELECT date, borough, round(avg(rent_median_asking_price),2) avg_change_by_month
FROM rent_price_info
LEFT JOIN area AS a
USING (area_id)
WHERE rent_median_asking_price IS NOT NULL
AND borough  IS NOT NULL
GROUP BY date, borough
ORDER BY date

--price by month overall
SELECT date, round(avg(rent_median_asking_price),2) avg_change_by_month
FROM rent_price_info
WHERE rent_median_asking_price IS NOT NULL
GROUP BY date
ORDER BY date

--compare price at 2020-01(highest before covid) and 2021-01(lowest point)
WITH before_covid AS
(SELECT bedroom_type_id, round(AVG(rent_median_asking_price),2) before_covid
FROM rent_price_info rp
WHERE rp.date = '2020-01'
GROUP BY bedroom_type_id),
lowest AS
(SELECT bedroom_type_id, round(AVG(rent_median_asking_price),2) lowest
FROM rent_price_info rp
WHERE rp.date = '2021-01'
GROUP BY bedroom_type_id)

SELECT bedroom_type, before_covid, lowest, before_covid - lowest AS diff, round((before_covid - lowest)/before_covid*100,2) drop_perc
FROM before_covid bc
LEFT JOIN lowest l
USING (bedroom_type_id)
LEFT JOIN room r
USING (bedroom_type_id)

--compare price at 2022-02(highest before covid) and 2021-01(lowest point)
WITH highest AS
(SELECT bedroom_type_id, round(AVG(rent_median_asking_price),2) highest
FROM rent_price_info rp
WHERE rp.date = '2022-02'
GROUP BY bedroom_type_id),
lowest AS
(SELECT bedroom_type_id, round(AVG(rent_median_asking_price),2) lowest
FROM rent_price_info rp
WHERE rp.date = '2021-01'
GROUP BY bedroom_type_id)

SELECT bedroom_type, lowest, highest, highest - lowest AS diff, round((highest - lowest)/lowest*100,2) increase_perc
FROM highest h
LEFT JOIN lowest l
USING (bedroom_type_id)
LEFT JOIN room r
USING (bedroom_type_id)

-- What is the top 20 area with highest rent median price among all the room types?
SELECT r.area_id, r.area_name, r.borough, rt.avg_rent
FROM(
SELECT rp.area_id, round(AVG(rp.rent_median_asking_price),2) AS avg_rent
FROM rent_price_info AS rp
WHERE rp.rent_median_asking_price IS NOT null
GROUP BY rp.area_id) rt
LEFT JOIN AREA AS r
ON rt.area_id = r.area_id
WHERE area_type = 'neighborhood'
ORDER BY rt.avg_rent DESC
LIMIT 20

-- What is the top 20 area with highest rent inventory? Is there any overlap with area with highest rent median price?
SELECT r.area_id, r.area_name, r.borough, rt.total_inventory
FROM(
SELECT ri.area_id, sum(ri.rent_inventory) AS total_inventory
FROM rent_inventory_info AS ri
WHERE ri.rent_inventory IS NOT null
GROUP BY ri.area_id) rt
LEFT JOIN AREA AS r
ON rt.area_id = r.area_id
WHERE area_type = 'neighborhood'
ORDER BY rt.total_inventory DESC
LIMIT 20

-- R Overlap area investigation
SELECT i.area_id, i.area_name, i.borough, i.total_inventory, p.avg_rent
FROM 
	(SELECT r.area_id, r.area_name, rt.total_inventory, r.borough
	FROM(
	SELECT ri.area_id, sum(ri.rent_inventory) AS total_inventory
	FROM rent_inventory_info AS ri
	WHERE ri.rent_inventory IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.total_inventory DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.avg_rent
	FROM(
	SELECT rp.area_id, round(AVG(rp.rent_median_asking_price),2) AS avg_rent
	FROM rent_price_info AS rp
	WHERE rp.rent_median_asking_price IS NOT null
	GROUP BY rp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.avg_rent DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id

-- R3. How did the average rent median price change per month in these areas?
SELECT a.area_name, a.borough, l.date, l.rent_median_asking_price
FROM
(SELECT area_id, date, rent_median_asking_price
FROM rent_price_info
WHERE area_id IN(
SELECT area_id
FROM (SELECT i.area_id, i.area_name, i.total_inventory, p.avg_rent
FROM 
	(SELECT r.area_id, r.area_name, rt.total_inventory
	FROM(
	SELECT ri.area_id, sum(ri.rent_inventory) AS total_inventory
	FROM rent_inventory_info AS ri
	WHERE ri.rent_inventory IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.total_inventory DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.avg_rent
	FROM(
	SELECT rp.area_id, round(AVG(rp.rent_median_asking_price),2) AS avg_rent
	FROM rent_price_info AS rp
	WHERE rp.rent_median_asking_price IS NOT null
	GROUP BY rp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.avg_rent DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id
	)AS ovlp)) l
LEFT JOIN area a
ON l.area_id = a.area_id

--R4. What is the rent price cut in these areas?
SELECT area_name, borough, min_cut, max_cut, avg_cut
FROM(
SELECT area_id, round(MIN(rent_price_cut),3) min_cut, round(MAX(rent_price_cut),3) max_cut, round(AVG(rent_price_cut),3) avg_cut
FROM rent_price_info
WHERE area_id IN
(
SELECT area_id
FROM (SELECT i.area_id, i.area_name, i.total_inventory, p.avg_rent
FROM 
	(SELECT r.area_id, r.area_name, rt.total_inventory
	FROM(
	SELECT ri.area_id, sum(ri.rent_inventory) AS total_inventory
	FROM rent_inventory_info AS ri
	WHERE ri.rent_inventory IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.total_inventory DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.avg_rent
	FROM(
	SELECT rp.area_id, round(AVG(rp.rent_median_asking_price),2) AS avg_rent
	FROM rent_price_info AS rp
	WHERE rp.rent_median_asking_price IS NOT null
	GROUP BY rp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.avg_rent DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id) AS a)
GROUP BY area_id) ri 
LEFT JOIN area a
ON a.area_id = ri.area_id

--R5. Compare with the 2020, what are the top 10 areas has the most average rent price increase across all room types in the 2021?
SELECT a.area_id, a.area_name, a.borough, d.avg_2020, d.avg_2021, d.diff_amount, round(d.diff_amount/d.avg_2020*100,2) AS diff_perc
FROM(
SELECT c1.area_id, avg_2020, avg_2021, avg_2021-avg_2020 AS diff_amount
FROM (SELECT area_id, round(avg(rent_median_asking_price),2) AS avg_2020
FROM rent_price_info
WHERE date like '2020%'
AND rent_median_asking_price IS NOT NULL
GROUP BY area_id) c1
LEFT JOIN 
(SELECT area_id, round(avg(rent_median_asking_price),2) AS avg_2021
FROM rent_price_info
WHERE date like '2021%'
AND rent_median_asking_price IS NOT NULL
GROUP BY area_id
) c2
ON c1.area_id = c2.area_id) d
LEFT JOIN area a 
ON a.area_id = d.area_id
WHERE area_type = 'neighborhood'
AND diff_amount IS NOT NULL
ORDER BY diff_amount DESC
LIMIT 10

----------------------------------------------------------------------------------------------------------------
--sales

--sale price over years
WITH table_2020 AS (
	SELECT borough, round(AVG(median_sales_price),2) AS avg_2020, 
					round(MIN(median_sales_price),2) AS min_2020, 
					round(MAX(median_sales_price),2) AS max_2020
	FROM sales_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2020%'
	AND median_sales_price  IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough
), table_2021 AS
	(SELECT borough, round(AVG(median_sales_price),2) AS avg_2021, 
					round(MIN(median_sales_price),2) AS min_2021, 
					round(MAX(median_sales_price),2) AS max_2021
	FROM sales_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2021%'
	AND median_sales_price IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough
), table_2022 AS
	(SELECT borough, round(AVG(median_sales_price),2) AS avg_2022, 
					round(MIN(median_sales_price),2) AS min_2022, 
					round(MAX(median_sales_price),2) AS max_2022
	FROM sales_price_info as ri
	LEFT JOIN area AS a
	USING (area_id)
	WHERE date like '2022%'
	AND median_sales_price IS NOT NULL
	AND borough  IS NOT NULL
	GROUP BY borough)
SELECT *
FROM table_2020
LEFT JOIN table_2021
USING (borough)
LEFT JOIN table_2022
USING (borough)

--price by month in each borough
SELECT date, borough, round(avg(median_sales_price),2) avg_change_by_month
FROM sales_price_info
LEFT JOIN area AS a
USING (area_id)
WHERE median_sales_price IS NOT NULL
AND borough  IS NOT NULL
GROUP BY date, borough
ORDER BY date

--price by month overall
SELECT date, round(avg(median_sales_price),2) avg_change_by_month
FROM sales_price_info
WHERE median_sales_price IS NOT NULL
GROUP BY date
ORDER BY date

--compare price at 2020-01(highest before covid) and 2021-01(lowest point)
WITH before_covid AS
(SELECT property_type_id, round(AVG(sales_recorded),2) before_covid
FROM sales_inventory_info rp
WHERE rp.date = '2020-01'
GROUP BY property_type_id),
lowest AS
(SELECT property_type_id, round(AVG(sales_recorded),2) lowest
FROM sales_inventory_info rp
WHERE rp.date = '2021-01'
GROUP BY property_type_id)

SELECT property_type, before_covid, lowest, before_covid - lowest AS diff, round((before_covid - lowest)/before_covid*100,2) drop_perc
FROM before_covid bc
LEFT JOIN lowest l
USING (property_type_id)
LEFT JOIN house r
USING (property_type_id)

--compare price at 2020-01(highest before covid) and 2021-01(lowest point)
WITH before_covid AS
(SELECT property_type_id, round(AVG(median_sales_price),2) before_covid
FROM sales_price_info rp
WHERE rp.date = '2020-01'
GROUP BY property_type_id),
lowest AS
(SELECT property_type_id, round(AVG(median_sales_price),2) lowest
FROM sales_price_info rp
WHERE rp.date = '2021-01'
GROUP BY property_type_id)

SELECT property_type, before_covid, lowest, before_covid - lowest AS diff, round((before_covid - lowest)/before_covid*100,2) drop_perc
FROM before_covid bc
LEFT JOIN lowest l
USING (property_type_id)
LEFT JOIN house r
USING (property_type_id)

--compare records at 2022-02(highest before covid) and 2021-01(lowest point)
WITH highest AS
(SELECT property_type_id, round(AVG(sales_recorded),2) sales_recorded_high
FROM sales_inventory_info rp
WHERE rp.date = '2022-02'
GROUP BY property_type_id),
lowest AS
(SELECT property_type_id, round(AVG(sales_recorded),2) sales_recorded_low
FROM sales_inventory_info rp
WHERE rp.date = '2021-01'
GROUP BY property_type_id)

SELECT property_type, sales_recorded_high, sales_recorded_low, sales_recorded_high - sales_recorded_low AS diff, round((sales_recorded_high - sales_recorded_low)/sales_recorded_low*100,2) increase_perc
FROM highest bc
LEFT JOIN lowest l
USING (property_type_id)
LEFT JOIN house r
USING (property_type_id)

--compare price at 2022-02(highest before covid) and 2021-01(lowest point)
WITH highest AS
(SELECT property_type_id, round(AVG(median_sales_price),2) highest
FROM sales_price_info rp
WHERE rp.date = '2022-02'
GROUP BY property_type_id),
lowest AS
(SELECT property_type_id, round(AVG(median_sales_price),2) lowest
FROM sales_price_info rp
WHERE rp.date = '2021-01'
GROUP BY property_type_id)

SELECT property_type, highest, lowest, highest - lowest AS diff, round((highest - lowest)/lowest*100,2) increase_perc
FROM highest bc
LEFT JOIN lowest l
USING (property_type_id)
LEFT JOIN house r
USING (property_type_id)

-- top property
SELECT h.property_type_id, h.property_type, i.total_records
FROM(
SELECT property_type_id, sum(sales_recorded) AS total_records
FROM sales_inventory_info AS ri
WHERE ri.sales_recorded IS NOT null
GROUP BY property_type_id) i
LEFT JOIN house AS h
ON h.property_type_id = i. property_type_id

--type + record
SELECT r.area_id, r.area_name, r.borough, h.property_type, i.total_records
FROM(
SELECT area_id, property_type_id, sum(sales_recorded) AS total_records
FROM sales_inventory_info AS ri
WHERE ri.sales_recorded IS NOT null
GROUP BY area_id, property_type_id
ORDER BY total_records DESC
) i
LEFT JOIN AREA AS r
ON i.area_id = r.area_id
LEFT JOIN house AS h
ON h.property_type_id = i. property_type_id
WHERE area_type = 'neighborhood'
LIMIT 20

-- What is the top 20 area with highest sales price?
SELECT r.area_id, r.area_name, r. borough, rt.avg_sales
FROM(
SELECT sp.area_id, round(AVG(sp.median_sales_price),2) AS avg_sales
FROM sales_price_info AS sp
WHERE sp.median_sales_price IS NOT null
GROUP BY sp.area_id) rt
LEFT JOIN AREA AS r
ON rt.area_id = r.area_id
WHERE area_type = 'neighborhood'
ORDER BY rt.avg_sales DESC
LIMIT 20

--S2. What is the top 20 area with highest sales records? Is there any overlap with area with highest sales price?
SELECT r.area_id, r.area_name, rt.total_recorded
FROM(
SELECT ri.area_id, sum(ri.sales_recorded) AS total_recorded
FROM sales_inventory_info AS ri
WHERE ri.sales_recorded IS NOT null
GROUP BY ri.area_id) rt
LEFT JOIN AREA AS r
ON rt.area_id = r.area_id
WHERE area_type = 'neighborhood'
ORDER BY rt.total_recorded DESC
LIMIT 20



--Overlap area investigation
SELECT i.area_id, i.area_name, i.borough, p.total_recorded, i.avg_sales
FROM (SELECT r.area_id, r.area_name, r. borough, rt.avg_sales
	FROM(
	SELECT sp.area_id, round(AVG(sp.median_sales_price),2) AS avg_sales
	FROM sales_price_info AS sp
	WHERE sp.median_sales_price IS NOT null
	GROUP BY sp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.avg_sales DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.total_recorded
	FROM(
	SELECT ri.area_id, sum(ri.sales_recorded) AS total_recorded
	FROM sales_inventory_info AS ri
	WHERE ri.sales_recorded IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.total_recorded DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id

-- How did the average sales price change per month in these areas?
SELECT a.area_name, a.borough, l.date, l.median_sales_price
FROM
(SELECT area_id, date, median_sales_price
FROM sales_price_info
WHERE area_id IN(
SELECT area_id
FROM (SELECT i.area_id, i.area_name, i.total_recorded, p.avg_sales
FROM (SELECT r.area_id, r.area_name, rt.total_recorded
	FROM(
	SELECT ri.area_id, sum(ri.sales_recorded) AS total_recorded
	FROM sales_inventory_info AS ri
	WHERE ri.sales_recorded IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.total_recorded DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, r. borough, rt.avg_sales
	FROM(
	SELECT sp.area_id, round(AVG(sp.median_sales_price),2) AS avg_sales
	FROM sales_price_info AS sp
	WHERE sp.median_sales_price IS NOT null
	GROUP BY sp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	WHERE area_type = 'neighborhood'
	ORDER BY rt.avg_sales DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id)AS ovlp)) l
LEFT JOIN area a
ON l.area_id = a.area_id

-- What is the sale price cut in these areas?
SELECT area_name, borough, min_sales_cut, max_sales_cut, avg_sales_cut
FROM(
SELECT area_id, MIN(sales_price_cut) min_sales_cut, MAX(sales_price_cut) max_sales_cut, round(AVG(sales_price_cut),3) avg_sales_cut
FROM sales_price_info
WHERE area_id IN
(
SELECT area_id
FROM (SELECT i.area_id, i.area_name, i.total_inventory, p.avg_sales
FROM (SELECT r.area_id, r.area_name, rt.total_inventory
	FROM(
	SELECT ri.area_id, sum(ri.sales_inventory) AS total_inventory
	FROM sales_inventory_info AS ri
	WHERE ri.sales_inventory IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	ORDER BY rt.total_inventory DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.avg_sales
	FROM(
	SELECT sp.area_id, round(AVG(sp.median_sales_price),2) AS avg_sales
	FROM sales_price_info AS sp
	WHERE sp.median_sales_price IS NOT null
	GROUP BY sp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	ORDER BY rt.avg_sales DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id) AS a)
GROUP BY area_id) ri 
LEFT JOIN area a
ON a.area_id = ri.area_id

-- What is the average difference between median asking price and median sales price?
SELECT area_name, borough, avg_sale, avg_ask, avg_sale - avg_ask diff_amount, round(avg_sale/avg_ask*100,2) percentage
FROM(
SELECT area_id, round(AVG(median_sales_price),2) avg_sale, round(AVG(sales_median_asking_price),2) avg_ask
FROM sales_price_info
WHERE area_id IN
(
SELECT area_id
FROM (
SELECT i.area_id, i.area_name, i.total_inventory, p.avg_sales
FROM (SELECT r.area_id, r.area_name, rt.total_inventory
	FROM(
	SELECT ri.area_id, sum(ri.sales_inventory) AS total_inventory
	FROM sales_inventory_info AS ri
	WHERE ri.sales_inventory IS NOT null
	GROUP BY ri.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	ORDER BY rt.total_inventory DESC
	LIMIT 20) AS i
INNER JOIN (
	SELECT r.area_id, r.area_name, rt.avg_sales
	FROM(
	SELECT sp.area_id, round(AVG(sp.median_sales_price),2) AS avg_sales
	FROM sales_price_info AS sp
	WHERE sp.median_sales_price IS NOT null
	GROUP BY sp.area_id) rt
	LEFT JOIN AREA AS r
	ON rt.area_id = r.area_id
	ORDER BY rt.avg_sales DESC
	LIMIT 20) AS p
ON i.area_id = p.area_id) AS a)
GROUP BY area_id) ri 
LEFT JOIN area a
ON a.area_id = ri.area_id

-- Compare with the 2020, what are the top 10 areas has the most average sales price increase across all room types in the 2021?
SELECT a.area_id, a.area_name, a.borough, d.avg_2020, d.avg_2021, d.diff_amount, round(d.diff_amount/d.avg_2020*100,2) AS diff_perc
FROM(
SELECT c1.area_id, avg_2020, avg_2021, avg_2021-avg_2020 AS diff_amount
FROM (SELECT area_id, round(avg(median_sales_price),2) AS avg_2020
FROM sales_price_info
WHERE date like '2020%'
AND median_sales_price IS NOT NULL
GROUP BY area_id) c1
LEFT JOIN 
(SELECT area_id, round(avg(median_sales_price),2) AS avg_2021
FROM sales_price_info
WHERE date like '2021%'
AND median_sales_price IS NOT NULL
GROUP BY area_id
) c2
ON c1.area_id = c2.area_id) d
LEFT JOIN area a 
ON a.area_id = d.area_id
WHERE diff_amount IS NOT NULL
ORDER BY diff_amount DESC
LIMIT 10



