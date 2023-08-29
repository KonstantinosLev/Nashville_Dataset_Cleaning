SELECT *
FROM nashville_housing

-- POPULATE DATA ADDRESS(fill nulls)
SELECT a.uniqueid,a.parcelid,a.propertyaddress,COALESCE(a.propertyaddress,b.propertyaddress)
FROM nashville_housing a
INNER JOIN nashville_housing b
ON a.parcelid=b.parcelid AND a.uniqueid<>b.uniqueid
WHERE a.propertyaddress IS NULL


UPDATE nashville_housing
SET propertyaddress=COALESCE(a.propertyaddress,b.propertyaddress)
FROM nashville_housing a
INNER JOIN nashville_housing b
ON a.parcelid=b.parcelid AND a.uniqueid<>b.uniqueid
WHERE a.propertyaddress IS NULL


-- BREAK DOWN ADDRESS (address,city,state)

SELECT SPLIT_PART(owneraddress,',',1) as owneraddres
      ,SPLIT_PART(owneraddress,',',2) as ownercity
	  ,SPLIT_PART(owneraddress,',',3) as ownerstate
FROM nashville_housing

ALTER TABLE nashville_housing
ADD owneraddres text

UPDATE nashville_housing
SET owneraddres=SPLIT_PART(owneraddress,',',1)
--
ALTER TABLE nashville_housing
ADD ownercity text

UPDATE nashville_housing
SET ownercity=SPLIT_PART(owneraddress,',',2)
--
ALTER TABLE nashville_housing
ADD ownerstate text

UPDATE nashville_housing
SET ownerstate=SPLIT_PART(owneraddress,',',3)


-- Y-N TO YES-NO IN soldasvacant FIELD

UPDATE nashville_housing
SET soldasvacant=LOWER(soldasvacant)
UPDATE nashville_housing
SET  soldasvacant=CASE WHEN soldasvacant='n' THEN 'no'
                       WHEN soldasvacant='y' THEN 'yes'
					   ELSE soldasvacant


-- REMOVE DUPLICATES
SELECT parcelid,propertyaddress,saledate,saleprice,legalreference,COUNT(*)
FROM nashville_housing
GROUP BY parcelid,propertyaddress,saledate,saleprice,legalreference
HAVING COUNT(*) >1

DELETE FROM nashville_housing a1
USING nashville_housing a2
WHERE a1.uniqueid<a2.uniqueid
AND a1.parcelid=a2.parcelid
AND a1.propertyaddress=a2.propertyaddress
AND a1.saledate=a2.saledate
AND a1.saleprice=a2.saleprice
AND a1.legalreference=a2.legalreference



-- DELETE UNUSED COLUMNS
ALTER TABLE nashville_housing
DROP COLUMN owneraddress,
DROP COLUMN taxdistrict,
DROP COLUMN propertyaddress


-- CONVERT TO THE RIGHT DATA TYPE


UPDATE nashville_housing
SET saleprice=REPLACE(REPLACE(saleprice,',',''),'$','')::numeric
UPDATE nashville_housing
SET saleprice=TRIM(saleprice)

--didnt work
UPDATE nashville_housing
SET saleprice=CAST(saleprice AS INTEGER)

--worked like a charm
ALTER TABLE nashville_housing 
ALTER COLUMN saleprice set data type integer
USING saleprice::INTEGER

ALTER TABLE nashville_housing 
ALTER COLUMN parcelid set data type bigserial
USING parcelid::bigserial

-------------------------------------------
-- FEW QUESTIONS

SELECT *
FROM nashville_housing



-- MIN, MAX, AVG, TOTALS

SELECT MIN(saleprice) as MINsaleprice,MAX(saleprice) as MAXsaleprice,
       AVG(saleprice) as AVGsaleprice,MAX(saleprice)- MIN(saleprice) as RANGEsaleprice,
	   percentile_cont(0.5) WITHIN GROUP (ORDER BY saleprice) as MEDIANsaleprice,
	   SUM(saleprice) as TOTALsaleprice
FROM nashville_housing



-- TOTAL AMOUNT PER YEAR

SELECT SUM(saleprice) as TTLSPENT,EXTRACT(YEAR FROM saledate) as year
FROM nashville_housing
GROUP BY year
ORDER BY 2



-- TOTAL HOUSES SOLD PER YEAR

SELECT COUNT(uniqueid),EXTRACT(YEAR FROM saledate) as year
FROM nashville_housing
GROUP BY year
HAVING COUNT(saleprice) is not null
ORDER BY 2



-- DATA FROM SPECIFIC YEARS 

SELECT saleprice, EXTRACT(YEAR FROM saledate) AS year,*
FROM nashville_housing
WHERE EXTRACT(YEAR FROM saledate) = 2019
      OR EXTRACT(YEAR FROM saledate) = 2013
ORDER BY year desc



-- 3 MOST PREFERABLE NUM OF BEDDROOMS

SELECT SUM(saleprice),bedrooms
FROM nashville_housing
GROUP BY bedrooms 
HAVING bedrooms is not null
ORDER BY 1 DESC
LIMIT 3


-- HOW MANY HOUSES GOT BUILT BOFORE AND AFTER 2000 (PER YEAR)

SELECT 
    yearbuilt,
    SUM(CASE WHEN yearbuilt >= 2000 THEN 1 ELSE 0 END) AS after2000,
    SUM(CASE WHEN yearbuilt < 2000 THEN 1 ELSE 0 END) AS before2000
FROM nashville_housing
GROUP BY yearbuilt
HAVING yearbuilt is not null
ORDER BY 1

-- HOW MANY HOUSES GOT BUILT BOFORE AND AFTER 2000 (TOTAL)

SELECT 
    SUM(CASE WHEN yearbuilt >= 2000 THEN 1 ELSE 0 END) AS BUILTafter2000,
    SUM(CASE WHEN yearbuilt < 2000 THEN 1 ELSE 0 END) AS BUILTbefore2000
FROM nashville_housing
WHERE yearbuilt IS NOT NULL;


