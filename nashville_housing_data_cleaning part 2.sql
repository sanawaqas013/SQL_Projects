DROP TABLE nashville_deleting;

CREATE TABLE nashville_deleting(
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
	half_bath integer);

SELECT * FROM nashville_deleting;

--import data
COPY nashville_deleting FROM 'D:\Nashville Housing Data for Data Cleaning.csv' DELIMITER ','CSV HEADER;

WITH duplicate_rows AS(
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY parcel_id, property_address, sale_price, sale_date, legal_reference
			ORDER BY unique_id
		) AS row_num
	FROM nashville_deleting
	ORDER BY parcel_id
)

DELETE FROM nashville_deleting
WHERE unique_id IN (
    SELECT unique_id
    FROM duplicate_rows
    WHERE row_num > 1
);

SELECT *
FROM duplicate_rows
WHERE row_num = 2
ORDER BY parcel_id;