SELECT * FROM nashville_housing_data;

--create table
CREATE TABLE nashville_housing_data(
	unique_id integer,
	parcel_id varchar(50),
	land_use varchar(50),
	property_address varchar(100),
	sale_date date,
	sale_price integer,
	legal_reference varchar(50),
	sold_as_vacant varchar(10),
	owner_name varchar(100),
	owner_address varchar(100),
	acreage numeric,
	tax_district varchar(50),
	land_value integer,
	building_value integer,
	total_value integer,
	year_built integer,
	bedrooms integer,
	full_bath integer,
	half_bath integer
)

--import data
COPY nashville_housing_data FROM 'D:\Nashville Housing Data for Data Cleaning.csv' DELIMITER ','CSV HEADER;

--populate property address data
SELECT *
FROM nashville_housing_data
WHERE property_address IS NULL
ORDER BY parcel_id;

SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address, COALESCE(a.property_address, b.property_address)
FROM nashville_housing_data AS a
JOIN nashville_housing_data AS b
	ON a.parcel_id = b.parcel_id
	AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL;

UPDATE nashville_housing_data
SET property_address = coalesce_property_address
FROM (
    SELECT COALESCE(a.property_address, b.property_address) as coalesce_property_address
    FROM nashville_housing_data as a
    JOIN nashville_housing_data as b
        ON a.parcel_id = b.parcel_id
        AND a.unique_id <> b.unique_id
    WHERE a.property_address IS NULL
) AS subquery
WHERE nashville_housing_data.parcel_id = subquery.parcel_id;

--split address into seperate columns
SELECT
	SUBSTRING(property_address, 1, POSITION(',' IN property_address)-1) AS address_1,
	SUBSTRING(property_address, POSITION(',' IN property_address)+1, LENGTH(property_address)) AS address_2
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data
ADD COLUMN property_address_updated varchar(50)
ADD COLUMN property_address_city varchar(50);

UPDATE nashville_housing_data
SET
	property_address_updated = SUBSTRING(property_address, 1, POSITION(',' IN property_address)-1),
	property_address_city = SUBSTRING(property_address, POSITION(',' IN property_address)+1, LENGTH(property_address));

SELECT unique_id, property_address, property_address_updated, property_address_city
FROM nashville_housing_data;

--split owner address into seperate columns
SELECT 
	owner_address,
    SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 1) AS owner_split_address,
    SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 2) AS owner_split_city,
    SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 3) AS owner_split_state
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data
ADD COLUMN owner_split_address VARCHAR(100),
ADD COLUMN owner_split_city VARCHAR(100),
ADD COLUMN owner_split_state VARCHAR(100);

UPDATE nashville_housing_data
SET 
	owner_split_address = SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 1),
	owner_split_city = SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 2),
	owner_split_state = SPLIT_PART(REPLACE(owner_address, ',', '.'), '.', 3);

SELECT owner_address, owner_split_address, owner_split_city, owner_split_state
FROM nashville_housing_data
ORDER BY unique_id;

--changing 'Y' and 'N' to 'Yes' and 'No'
SELECT DISTINCT sold_as_vacant, COUNT(sold_as_vacant)
FROM nashville_housing_data
GROUP BY sold_as_vacant
ORDER BY 2;

SELECT sold_as_vacant,
	CASE 
		WHEN sold_as_vacant = 'Y' THEN 'Yes'
		WHEN sold_as_vacant = 'N' THEN 'No'
		ELSE sold_as_vacant
	END as updated_case
FROM nashville_housing_data
WHERE sold_as_vacant = 'N' OR sold_as_vacant = 'Y';

UPDATE nashville_housing_data
SET sold_as_vacant = updated_case
FROM (
	SELECT unique_id, CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
	WHEN sold_as_vacant = 'N' THEN 'No'
	ELSE sold_as_vacant
	END as updated_case
	FROM nashville_housing_data
) AS sub
WHERE nashville_housing_data.unique_id = sub.unique_id;

SELECT DISTINCT(sold_as_vacant), COUNT(sold_as_vacant)
FROM nashville_housing_data
GROUP BY sold_as_vacant;

--filtering out duplicates
WITH duplicate_rows AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
            ORDER BY unique_id
        ) AS row_num
    FROM nashville_housing_data
    ORDER BY parcel_id
)

SELECT *
FROM duplicate_rows
WHERE row_num > 1
ORDER BY parcel_id;

--104/56477 duplicate rows found

SELECT *
FROM nashville_housing_data;

--deleting duplicate rows
WITH duplicate_rows_2 AS(
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
			ORDER BY unique_id
		) AS row_num
	FROM nashville_housing_data
)

DELETE FROM nashville_housing_data
WHERE unique_id IN (
    SELECT unique_id
    FROM duplicate_rows
    WHERE row_num > 1
);
