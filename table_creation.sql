CREATE TABLE area
	(area_id		integer,
	 areaname		varchar(100) NOT NULL,
	 borough		varchar(100),
	 area_type		varchar(100),
	 primary key 	(area_id)
	);
	
CREATE TABLE bedroom_type
	(bedroom_type_id	integer,
	 bedroom_type		varchar(100) NOT NULL,
	 primary key 		(bedroom_type_id)
	);


CREATE TABLE property_type
	(property_type_id	integer,
	 property_type		varchar(100) NOT NULL,
	 primary key 		(property_type_id)
	);
	
CREATE TABLE rent_price
	(rent_price_id			integer,
	 date					DATE NOT NULL,
	 medianAskingprice		integer,
	 share_of_pricecut		numeric(4,3),
	 primary key 			(rent_price_id)
	);

CREATE TABLE rent_inventory
	(rent_inventory_id		integer,
	 date					DATE NOT NULL,
	 rent_inventory			integer,
	 primary key 			(rent_inventory_id)
	);

CREATE TABLE sales_price
	(sales_price_id			integer,
	 date					DATE NOT NULL,
	 medianAskingprice		integer,
	 medianSaleprice		integer,
	 share_of_pricecut		numeric(4,3),
	 primary key 			(sales_price_id)
	);

CREATE TABLE sales_inventory
	(sales_inventory_id		integer,
	 date					DATE NOT NULL,
	 sales_inventory		integer,
	 recorded_sales			integer,
	 primary key 			(sales_inventory_id)
	);
	
CREATE TABLE rentinventory_area
	(rent_inventory_id		integer,
	 area_id				integer,
	 foreign key (rent_inventory_id) references rent_inventory(rent_inventory_id),
	 foreign key (area_id) references area(area_id)
	);

CREATE TABLE rentinventory_bedroomtype
	(rent_inventory_id		integer,
	 bedroom_type_id		integer,
	 foreign key (rent_inventory_id) references rent_inventory (rent_inventory_id),
	 foreign key (bedroom_type_id) references bedroom_type (bedroom_type_id)
	);
	
CREATE TABLE rentprice_area
	(rent_price_id			integer,
	 area_id				integer,
	 foreign key (rent_price_id) references rent_price (rent_price_id),
	 foreign key (area_id) references area (area_id)
	);
	
CREATE TABLE rentprice_bedroomtype
	(rent_price_id			integer,
	 bedroom_type_id		integer,
	 foreign key (rent_price_id) references rent_price (rent_price_id),
	 foreign key (bedroom_type_id) references bedroom_type (bedroom_type_id)
	);

CREATE TABLE salesprice_property_type
	(sales_price_id			integer,
	 property_type_id		integer,
	 foreign key (sales_price_id) references sales_price (sales_price_id),
	 foreign key (property_type_id) references property_type (property_type_id)
	);

CREATE TABLE salesprice_area
	(sales_price_id			integer,
	 area_id				integer,
	 foreign key (sales_price_id) references sales_price (sales_price_id),
	 foreign key (area_id) references area (area_id)
	);

CREATE TABLE salesinventory_property_type
	(sales_inventory_id		integer,
	 property_type_id		integer,
	 foreign key (sales_inventory_id) references sales_inventory (sales_inventory_id),
	 foreign key (property_type_id) references property_type (property_type_id)
	);
	
CREATE TABLE salesinventory_area
	(sales_inventory_id		integer,
	 area_id				integer,
	 foreign key (sales_inventory_id) references sales_inventory (sales_inventory_id),
	 foreign key (area_id) references area (area_id)
	);