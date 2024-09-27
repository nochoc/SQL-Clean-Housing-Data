USE clean_date;

SELECT * FROM housingdata;

DESC housingdata;

# Date is stored as text, need to convert to date format
ALTER TABLE housingdata
MODIFY COLUMN SaleDate date;

SELECT * FROM housingdata;
DESC housingdata;

-- --------------------------------------------------------------------------------------

SELECT * FROM housingdata
WHERE PropertyAddress IS NULL; -- Property Address should not be NULL, lets investigate

SELECT * FROM housingdata
ORDER BY UniqueID; -- Notice that there are some duplicate entries (eg: UniqueID 148 and 149 have the same values for the other columns)

# Check one of the uniqueIDs where PropertyAddress is null by ParcelID
SELECT * FROM housingdata
WHERE ParcelID = '025 07 0 031.00'; -- We find that there is another row with the same ParcelID but differnt SaleDate,SalePrice, and LegalRegerence, but all else the same.

# Create a join
SELECT * FROM housingdata a
JOIN housingdata b
ON a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID
ORDER BY a.UniqueID;

# Find all the PropertyAddress with NULLS
SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress FROM housingdata a
JOIN housingdata b
ON a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

# Populate the NULLS
SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress) as PropertyAddress
FROM housingdata a
JOIN housingdata b
ON a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE housingdata a,housingdata b
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL
AND a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID;
-- now we have no more NULLS in PropertyAddress

-- ----------------------------------------------

	# Separate PropertyAddress into different columns
SELECT substring_index(PropertyAddress,',',1) FROM housingdata; -- this gives us the Street
SELECT substring_index(PropertyAddress,',',-1) FROM housingdata; -- this gives us the City

# Create new columns
ALTER TABLE housingdata
ADD COLUMN StreetAddress VARCHAR(255),
ADD COLUMN City VARCHAR(255);

# Assign values to the columns
UPDATE housingdata
SET 
StreetAddress = substring_index(PropertyAddress,',',1),
City = substring_index(PropertyAddress,',',-1);

SELECT StreetAddress,City,PropertyAddress FROM housingdata;

-- --------------------------

	# Repeat for OwnerAddress
SELECT substring_index(OwnerAddress,',',1) FROM housingdata; -- StreetAddress
SELECT SUBSTRING_INDEX(substring_index(OwnerAddress,',',2),',',-1) FROM housingdata; -- City
SELECT substring_index(OwnerAddress,',',-1) FROM housingdata; -- State

# Create new columns
ALTER TABLE housingdata
ADD COLUMN OwnerStreetAddress VARCHAR(255),
ADD COLUMN OwnerCity VARCHAR(255),
ADD COLUMN OwnerState VARCHAR(255);

# Assign values to the columns
UPDATE housingdata
SET 
OwnerStreetAddress = substring_index(OwnerAddress,',',1),
OwnerCity = SUBSTRING_INDEX(substring_index(OwnerAddress,',',2),',',-1),
OwnerState = substring_index(OwnerAddress,',',-1);

SELECT OwnerStreetAddress,OwnerCity,OwnerState,OwnerAddress FROM housingdata;

-- ---------------------------------

	# Change Y and N to Yes and No in "Sold as Vacant" field
-- Some of the rows have Y and N instead of Yes and No
SELECT SoldAsVacant FROM housingdata;
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) FROM housingdata
GROUP BY SoldAsVacant;

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    ELSE SoldAsVacant
End
FROM housingdata;

# update data
Update housingdata
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    ELSE SoldAsVacant
End;

# check again
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) FROM housingdata
GROUP BY SoldAsVacant; -- no more Y and N --> SUCCESS

-- ------------

# Remove Duplicates using Window Functions
select * from housingdata;

With temp as(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
        ORDER BY UniqueID ) as rn
FROM housingdata)
SELECT * FROM temp where rn > 1; -- these are duplicates

# Delete the duplicates
With temp as(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
        ORDER BY UniqueID ) as rn
FROM housingdata)
DELETE FROM temp where rn > 1; -- cant delete from CTE

# Use temp table
CREATE TEMPORARY TABLE temp AS
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
        ORDER BY UniqueID ) as rn
FROM housingdata;

SELECT * FROM temp WHERE rn > 1;

# Delete duplicates in temp table
DELETE FROM temp WHERE rn > 1;

SELECT * FROM temp;

# Drop columns we no longer need from temp table
ALTER TABLE temp
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN LegalReference,
DROP COLUMN rn;

-- Now we have prepared a temp table for analysis
SELECT * FROM temp;



