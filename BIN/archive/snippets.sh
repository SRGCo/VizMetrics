############# CA single row for each unique poskey
#### where card template like '%Loyal%'

SELECT * FROM CardActivity_Live WHERE RowID IN (SELECT MAX(RowID) FROM CardActivity_Live GROUP BY POSKey) AND CardTemplate like '%Loyal%' ORDER BY `CardActivity_Live`.`StoreNumber` ASC

	SELECT CardActivity_Live.* WHERE RowID IN (SELECT MAX(RowID) FROM CardActivity_Live GROUP BY POSKey) AND CardTemplate like '%Loyal%' INTO OUTFILE '/home/srg/db_files/incoming/uniquekey.pxcardactivity.csv' FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' FROM CardActivity_Live; 







## show count of distinct/dupe in a field

SELECT COUNT(*), POSkey FROM ItemDetail_temp group by POSkey HAVING count(*) > 1 ORDER BY COUNT(*) DESC 






################# SHOULD NEVER NEED TO RUN THESE AGAIN #############################
####################################################################################

################# ITEM DETAIL LEGACY DEPARTMENT FIX SECTION   ######################

################ LAT ###################
#### LAT ENTREE TO SANDWICHES




#UPDATE ItemDetail_Live SET SaleDepartmentID = "34", SaleDepartmentName = "Sandwiches" WHERE LocationID  = '2' and 
(ItemID = '772'
OR ItemID = '703'
OR ItemID = '803'
OR ItemID = '717'
OR ItemID = '5419'
OR ItemID = '720'
OR ItemID = '5410'
OR ItemID = '723'
OR ItemID = '643'
OR ItemID = '831'
OR ItemID = '8308'
OR ItemID = '8309'
OR ItemID = '8311'
OR ItemID = '8848');

###### LAT ENTREES TO SALAD ADD ONS
#UPDATE ItemDetail_Live SET SaleDepartmentID = "43", SaleDepartmentName = "SALAD ADD ONS" WHERE LocationID  = '2' and 
(ItemID = '3497'
OR ItemID = '5298');


########### HALE ###############
#### HALE ST ENTREE TO SANDWICHES
#UPDATE ItemDetail_Live SET SaleDepartmentID = "34", SaleDepartmentName = "Sandwiches" WHERE LocationID  = '4' and 
(ItemID = '366'
OR ItemID = '7862'
OR ItemID = '2519'
OR ItemID = '1654'
OR ItemID = '1661'
OR ItemID = '469'
OR ItemID = '287'
OR ItemID = '505'
OR ItemID = '5553'
OR ItemID = '470'
OR ItemID = '5402'
OR ItemID = '106');

#### HALE ST ENTREE (and app) TO SPECIALS
#UPDATE ItemDetail_Live SET SaleDepartmentID = "69", SaleDepartmentName = "Specials" WHERE LocationID  = '4' and 
(ItemID = '9306'
OR ItemID = '2688'
OR ItemID = '3670'
OR ItemID = '3829'
OR ItemID = '5674'
OR ItemID = '10546');


#### HALE ST apps TO soups
#UPDATE ItemDetail_Live SET SaleDepartmentID = "47", SaleDepartmentName = "Soup" WHERE LocationID  = '4' and 
(ItemID = '414'
OR ItemID = '527'
OR ItemID = '404'
OR ItemID = '415');



######## OPUS ########

#### Opus ITEMS TO Soup
#UPDATE ItemDetail_Live SET SaleDepartmentID = "47", SaleDepartmentName = "Soup" WHERE LocationID  = '6' and 
(ItemID = '6650'
OR ItemID = '1857'
OR ItemID = '1381'
OR ItemID = '9358'
OR ItemID = '4139'
OR ItemID = '6296'
OR ItemName = 'CHILI');

#### Opus ITEMS TO Salad
#UPDATE ItemDetail_Live SET SaleDepartmentID = "7", SaleDepartmentName = "Salad" WHERE LocationID  = '6' and 
(ItemID = '4140'
OR ItemID = '6291'
OR ItemID = '1436'
OR ItemID = '1391'
OR ItemID = '1787'
OR ItemID = '6292'
OR ItemID = '9659'
OR ItemID = '7420'
OR ItemID = '9849'
OR ItemID = '10207'
OR ItemID = '1052'
OR ItemID = '9057'
OR ItemName = 'caesar'
OR ItemName = 'Opus Bowl'
OR ItemName = 'Arugula Salad'
OR ItemName = 'Duck Salad'
OR ItemName = 'House'
OR ItemName = 'Beet Salad');


#### OPUS ITEMS TO Sandwiches
#UPDATE ItemDetail_Live SET SaleDepartmentID = "34", SaleDepartmentName = "Sandwiches" WHERE LocationID  = '6' and 
(ItemName = 'Mav Burger'
OR ItemName = 'Opus Burger'
OR ItemName = 'Naan Grilled Chz'
OR ItemName = 'Naan Grl Chz'
OR ItemName = 'SLIDERS'
OR ItemName = 'Sandwich Steak'
OR ItemName = 'Banh Mi Tacos'
OR ItemName = 'Taco Spec'
OR ItemName = 'Opus Burger Br'
OR ItemName = 'Italian Sandwich'
OR ItemName = 'STEAK SANDWICH');


#### OPUS ITEMS TO Appetizer
#UPDATE ItemDetail_Live SET SaleDepartmentID = "8", SaleDepartmentName = "Appetizer" WHERE LocationID  = '6' and 
(ItemName = 'Duck Tasting');

#### OPUS ITEMS TO Entrees
#UPDATE ItemDetail_Live SET SaleDepartmentID = "4", SaleDepartmentName = "Entrees" WHERE LocationID  = '6' and 
(ItemName = 'Fish & Chips'
OR ItemName = 'Bolognese');


#### OPUS ITEMS TO Desserts
#UPDATE ItemDetail_Live SET SaleDepartmentID = "20", SaleDepartmentName = "Desserts" WHERE LocationID  = '6' and 
(ItemName = 'TIRAMISU'
OR ItemName = 'PROFITEROLS');

#### OPUS ITEMS TO Sushi
#UPDATE ItemDetail_Live SET SaleDepartmentID = "40", SaleDepartmentName = "SUSHI" WHERE LocationID  = '6' and 
(ItemName = 'Tommy Roll'
OR ItemName = 'TB12 Roll'
OR ItemName = 'Sakura Roll');

#### OPUS ITEMS TO Food Preps
#UPDATE ItemDetail_Live SET SaleDepartmentID = "5", SaleDepartmentName = "Food Preps" WHERE LocationID  = '6' and 
(ItemName = 'Bacon'
OR ItemName = 'Bacon - Add'
OR ItemName = 'Bacon - No'
OR ItemName = 'Bacon - Sub'
OR ItemName = 'Bacon - Xtra');


##### OPUS SALAD ADD ONS DO NOT APPEAR TO HAVE HISTORICAL ?  CREATED ADD ON CONDIMENT GROUPS WHEN CENI JOINED

######################################################################################################################
################################## END LEGACY FIX ####################################################################
######################################################################################################################


