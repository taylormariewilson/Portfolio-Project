SELECT *
FROM master.dbo.NashvilleHousingData;

-- Standardize sale date format
SELECT SaleDate, CONVERT(date, SaleDate)
FROM master.dbo.NashvilleHousingData;

UPDATE NashvilleHousingData
SET SaleDate = CONVERT(date, SaleDate);

ALTER TABLE NashvilleHousingData
ADD SaleDateConverted date;

UPDATE NashvilleHousingData
SET SaleDateConverted = CONVERT(date, SaleDate);

SELECT SaleDateConverted
FROM master.dbo.NashvilleHousingData;

-- Populate property address data

SELECT *
FROM master.dbo.NashvilleHousingData
ORDER BY ParcelID;

-- Populating null PropertyAddress fields with the property address of parcels with same ParcelID
SELECT NHD1.ParcelID, NHD1.PropertyAddress, NHD2.ParcelID, NHD2.PropertyAddress, ISNULL(NHD1.PropertyAddress, NHD2.PropertyAddress)
FROM master.dbo.NashvilleHousingData NHD1
JOIN master.dbo.NashvilleHousingData NHD2
ON NHD1.ParcelID = NHD2.ParcelID
AND NHD1.UniqueID <> NHD2.UniqueID
WHERE NHD1.PropertyAddress IS NULL;

-- Updating table to reflect newly populated PropertyAddress fields
UPDATE NHD1
SET PropertyAddress = ISNULL(NHD1.PropertyAddress, NHD2.PropertyAddress)
FROM master.dbo.NashvilleHousingData NHD1
JOIN master.dbo.NashvilleHousingData NHD2
ON NHD1.ParcelID = NHD2.ParcelID
AND NHD1.UniqueID <> NHD2.UniqueID
WHERE NHD1.PropertyAddress IS NULL;

SELECT PropertyAddress
FROM master.dbo.NashvilleHousingData;

-- Splitting property address into separated fields for street address and city name using SUBSTRING()
SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address
FROM master.dbo.NashvilleHousingData;

-- Add PropertySplitAddress to table, setting PropertySplitAddress as street address
ALTER TABLE NashvilleHousingData
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

-- Add PropertySplitCity to table, setting PropertySplitCity as city name
ALTER TABLE NashvilleHousingData
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousingData
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Splitting OwnerAddress into separate fields by street address, city, and state using PARSENAME()
SELECT OwnerAddress
FROM master.dbo.NashvilleHousingData;

SELECT 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS OwnerSplitAddress,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS OwnerState
FROM master.dbo.NashvilleHousingData;

ALTER TABLE NashvilleHousingData
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3);

ALTER TABLE NashvilleHousingData
ADD OwnerCity NVARCHAR(255);

UPDATE NashvilleHousingData
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2);

ALTER TABLE NashvilleHousingData
ADD OwnerState NVARCHAR(255);

UPDATE NashvilleHousingData
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1);

SELECT *
FROM master.dbo.NashvilleHousingData;

-- Change Y to Yes and N to No in "Sold As Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM master.dbo.NashvilleHousingData
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM master.dbo.NashvilleHousingData;

UPDATE NashvilleHousingData
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Removing duplicates via CTE

WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM master.dbo.NashvilleHousingData
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

-- Deleting unused columns

SELECT *
FROM master.dbo.NashvilleHousingData;

ALTER TABLE master.dbo.NashvilleHousingData
DROP COLUMN OwnerAddress, PropertyAddress;
