
use portofolioprojects;
###standardize date format
SELECT SaleDate,
STR_TO_DATE(SaleDate, '%M %d, %Y') AS ConvertedSaleDate
FROM Nashville_Housing;

UPDATE Nashville_Housing
SET SaleDate = ConvertedSaleDate;

###populate Property Address data 
##同一个parcel id, property address应该一样，用join和isnull（）实现替换

SELECT a.ParcelID,b.ParcelID,a.PropertyAddress,b.PropertyAddress,coalesce(a.PropertyAddress,b.PropertyAddress)
FROM Nashville_Housing a
join Nashville_Housing b 
on a.ParcelID=b.ParcelID and a.UniqueID!=b.UniqueID
where a.PropertyAddress is NULL;

UPDATE Nashville_Housing a
JOIN Nashville_Housing b 
  ON a.ParcelID = b.ParcelID 
  AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
  
select PropertyAddress
from Nashville_Housing;

###breaking out Address into Individual Columns (Address, City, State)

select substr(PropertyAddress,1,instr(PropertyAddress,",") - 1) as PropertysplitAddress, ##从第一个字母到comma前的一个字母
substr(PropertyAddress,instr(PropertyAddress,",") + 1) as PropertysplitCity 
##从comma后的一个字母到这个string的最后一个字母，所以不需要加上len(PropertyAddress)做参数
from Nashville_Housing;

ALTER TABLE Nashville_Housing
ADD PropertysplitAddress VARCHAR(255), ##This column will be able to store string values up to 255 characters long
ADD PropertysplitCity VARCHAR(255);

UPDATE Nashville_Housing
SET 
    PropertysplitAddress = SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1),
    PropertysplitCity = SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',') + 1);

select OwnerAddress
from Nashville_Housing;

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) as Part1,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) as Part2,
SUBSTRING_INDEX(OwnerAddress, ',', -1) as Part3
FROM Nashville_Housing; 

alter table Nashville_Housing
ADD OwnersplitAddress VARCHAR(255), 
ADD OwnersplitCity VARCHAR(255),
ADD OwnersplitState VARCHAR(255);

update Nashville_Housing
set 
   OwnersplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
   OwnersplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
   OwnersplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);
   
###change Y and N to Yes and No in the SoldAsVacant field

select distinct(SoldAsVacant),count(SoldAsVacant)
from Nashville_Housing
group by(SoldAsVacant)
order by SoldAsVacant;

select SoldAsVacant,
case
when SoldAsVacant = 'N' then 'No'
when SoldAsVacant = 'Y' then 'Yes'
else SoldAsVacant
end 
from Nashville_Housing;

update Nashville_Housing
set SoldAsVacant = case
when SoldAsVacant = 'N' then 'No'
when SoldAsVacant = 'Y' then 'Yes'
else SoldAsVacant
end ;

###removing duplicates
##find the duplicated rows
with RowNumCTE as(
select *,
row_number() over(
partition by ParcelID,
             PropertyAddress,
             SaleDate,
             SalePrice,
             LegalReference
             order by UniqueID
) as row_num
from Nashville_Housing
order by ParcelID)
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress;

##delete the duplicated rows 
##先用 CTE 或子查询标记需要删除的行。
##use a JOIN to connect the original table with the result of the CTE 
with RowNumCTE as(
select UniqueID,  -- 选择唯一标识列
row_number() over(
partition by ParcelID,
             PropertyAddress,
             SaleDate,
             SalePrice,
             LegalReference
             order by UniqueID
) as row_num
from Nashville_Housing
order by ParcelID)
DELETE nh
FROM Nashville_Housing nh
JOIN RowNumCTE cte ON nh.UniqueID = cte.UniqueID
WHERE cte.row_num > 1;


##delete unused columns

select *
from Nashville_Housing;

ALTER TABLE Nashville_Housing
drop column PropertyAddress,
drop column OwnerAddress,
drop column TaxDistrict


