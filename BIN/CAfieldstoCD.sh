

UPDATE Master_test SET DOB = TransactionDate (this requires our datefix varchar to date)
UPDATE Master_test SET LocationID = LocationID_px (Did we fix locationID earlier for POSKEY?)
UPDATE Master_test SET CheckNumber = MT.Checkno (squashed table does not have check number)

CA.DOB=MT.TransactionDate
CA.LocationId != MT.StoreNumber (CTUIT v PX)
CA.CheckNumber = MT.Checkno
there is no terminalID in CA
there is no Cashier ID in CA
