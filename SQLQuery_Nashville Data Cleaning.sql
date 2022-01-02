-- Verify that all the Data Has been uploaded successfully to the SSMS
SELECT *
FROM NashvilleHousingDB..NashvilleHousing
ORDER BY [UniqueID ]

-- Doing some basic queries to initiate the Data Cleansing 
SELECT OwnerName
FROM NashvilleHousing
Where OwnerName IS NOT NULL

---------------------------------------------------------------
-- Step 1 : Standardize the Date Format

SELECT *
FROM NashvilleHousingDB..NashvilleHousing
ORDER BY [UniqueID ]

SELECT SaleDate, CONVERT(Date, SaleDate) AS ConvertedDate
FROM NashvilleHousingDB..NashvilleHousing
ORDER BY SaleDate

-- Method 1 : To modify the table 
UPDATE NashvilleHousingDB..NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Viewing the Table to check the modifications
SELECT *
FROM NashvilleHousingDB..NashvilleHousing
ORDER BY [UniqueID ]

-- Method 2 : Altering directly the table

-- Adding a new empty Column
ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD SaleDateConverted Date

-- Checking for the creation of the new column
SELECT *
FROM NashvilleHousingDB..NashvilleHousing

-- Updating the Created Column to a converted Date Format
UPDATE NashvilleHousingDB..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Rechecking for the convertion
SELECT *
FROM NashvilleHousingDB..NashvilleHousing

---------------------------------------------------------------

-- Step 2 : Populate Missing Property Adress Data

-- Checking for Missing values in Property Adress Field
SELECT UniqueID, PropertyAddress
FROM NashvilleHousingDB..NashvilleHousing
WHERE PropertyAddress IS NULL

-- Checking for the similarity and the missing values
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
FROM NashvilleHousingDB..NashvilleHousing A
INNER JOIN NashvilleHousingDB..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL


-- Now we will replace the The A.PropertyAddress with the B.PropertyAddress when it is Null
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress) AS FilledPropertyAddress
FROM NashvilleHousingDB..NashvilleHousing A
INNER JOIN NashvilleHousingDB..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL


-- Now we will add the Filled Property Adress column to our table
ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD FilledPropertyAddress nvarchar(255)

-- Now we will update the created column by adding the filled propoerty address data
UPDATE A
SET 
	FilledPropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM 
	NashvilleHousingDB..NashvilleHousing A
INNER JOIN NashvilleHousingDB..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

-- Query for checking
SELECT ParcelID, FilledPropertyAddress
FROM NashvilleHousingDB..NashvilleHousing

-- Didn't work with the new column creation, we will procede only y modifying the existing data column
UPDATE A
SET 
	PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM 
	NashvilleHousingDB..NashvilleHousing A
INNER JOIN NashvilleHousingDB..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress is NULL

-- Query to check if the update query worked or not, and it seems to be working, i hope :p
SELECT *
FROM NashvilleHousingDB..NashvilleHousing
WHERE PropertyAddress is null

---------------------------------------------------------------

-- Step 3  Breaking out Address into indivadual columns (Adress, City, State)

SELECT PropertyAddress
FROM NashvilleHousingDB..NashvilleHousing


-- We will procede by indexing the Substring
SELECT 
	PropertyAddress, 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM 
	NashvilleHousingDB..NashvilleHousing


ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousingDB..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousingDB..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


 
-- Splitting the OwnerAddress field

SELECT OwnerAddress
FROM NashvilleHousingDB..NashvilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM
	NashvilleHousingDB..NashvilleHousing
ORDER BY [UniqueID ]

---- Altering the Table once again to Add the Owner Address, city and state

-- Adding the Columns
ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE NashvilleHousingDB..NashvilleHousing
ADD OwnerSplitState nvarchar(255);


-- Updating the columns
UPDATE NashvilleHousingDB..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


UPDATE NashvilleHousingDB..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousingDB..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--- Checking for the Table 
SELECT *
FROM NashvilleHousingDB..NashvilleHousing



---------------------------------------------------------------

--- Turning Y and N in the SoldAsVacant Field to Yes and No
SELECT DISTINCT 
	SoldAsVacant, 
	count(SoldAsVacant) AS CountSoldAsVacant
FROM 
	NashvilleHousingDB..NashvilleHousing
GROUP BY 
	SoldAsVacant
ORDER BY
	CountSoldAsVacant


-- Replacing the Values with Yes and No
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END AS ModifiedSoldAsVacant 
FROM
	NashvilleHousingDB..NashvilleHousing

-- Altering the field SoldAsVacant in the SQL Table

UPDATE NashvilleHousingDB..NashvilleHousing
SET SoldAsVacant = 	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
	END 

SELECT SoldAsVacant 
FROM NashvilleHousingDB..NashvilleHousing

-- Verification checked


---------------------------------------------------------------

-- Removing Duplicate Values
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress, 
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
						UniqueID
						) row_num
FROM NashvilleHousingDB..NashvilleHousing
)

--SELECT * 
--FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY PropertyAddress

DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Recheck for duplicates deleting

--SELECT * 
--FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY PropertyAddress


---------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM NashvilleHousingDB..NashvilleHousing 

ALTER TABLE NashvilleHousingDB..NashvilleHousing 
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

ALTER TABLE NashvilleHousingDB..NashvilleHousing 
DROP COLUMN SaleDate

ALTER TABLE NashvilleHousingDB..NashvilleHousing 
DROP COLUMN TaxDistrict

SELECT *
FROM NashvilleHousingDB..NashvilleHousing 
