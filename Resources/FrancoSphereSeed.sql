-- CHECKSUM:84c394cdd7343406822647231843acf1d05d12986bd699dac02a032370b9e2ec
-- Auto-generated – DO NOT EDIT.
BEGIN IMMEDIATE;

INSERT INTO routine_tasks ("building","taskName","startHour","endHour","daysOfWeek","recurrence") VALUES
('131 Perry Street','Sidewalk + Curb Sweep / Trash Return','6','7','Mon,Tue,Wed,Thu,Fri','Daily'),
('131 Perry Street','Hallway & Stairwell Clean / Vacuum','7','8','Mon,Wed','Weekly'),
('131 Perry Street','','','','',''),
('68 Perry Street','Sidewalk / Curb Sweep & Trash Return','8','9','Mon,Tue,Wed,Thu,Fri','Daily'),
('68 Perry Street','Full Building Clean & Vacuum','8','9','Tue,Thu','Weekly'),
('68 Perry Street','Stairwell Hose-Down + Trash Area Hose','9','9','Mon,Wed,Fri','Weekly'),
('135–139 West 17th','Trash Area + Sidewalk & Curb Clean','10','11','Mon,Tue,Wed,Thu,Fri','Daily'),
('136 West 17th','Trash Area + Sidewalk & Curb Clean','10','11','Mon,Tue,Wed,Thu,Fri','Daily'),
('138 West 17th Street','Trash Area + Sidewalk & Curb Clean','11','12','Mon,Tue,Wed,Thu,Fri','Daily'),
('117 West 17th Street','Trash Area Clean','11','12','Mon,Tue,Wed,Thu,Fri','Daily'),
('112 West 18th Street','Trash Area Clean','11','12','Mon,Tue,Wed,Thu,Fri','Daily'),
('29–31 East 20th','Hallway / Glass / Sidewalk Sweep & Mop','13','14','Tue','Weekly'),
('123 1st Ave','Hallway & Curb Clean','13','14','Tue,Thu','Weekly'),
('178 Spring','Stair Hose & Garbage Return','14','15','Mon,Wed,Fri','Weekly'),
('135–139 West 17th','','','','',''),
('136 West 17th','','','','',''),
('138 West 17th Street','','','','',''),
('178 Spring','','','','',''),
('112 West 18th Street','Glass & Lobby Clean','6','7','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('117 West 17th Street','Glass & Lobby Clean','7','8','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('135–139 West 17th','Glass & Lobby Clean','8','9','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('136 West 17th','Glass & Lobby Clean','9','10','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('138 West 17th Street','Glass & Lobby Clean','10','11','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('104 Franklin','Office Deep Clean','14','16','Mon,Thu','Weekly'),
('Stuyvesant Cove Park','Morning Park Check','6','7','Mon,Tue,Wed,Thu,Fri,Sat,Sun','Daily'),
('Stuyvesant Cove Park','Power Wash Walkways','7','9','','Monthly'),
('133 East 15th Street','Building Walk-Through','9','10','Mon,Wed,Fri','Weekly'),
('133 East 15th Street','Boiler Blow-Down','9','9','Mon','Weekly'),
('FrancoSphere HQ','Scheduled Repairs & Follow-ups','13','15','Mon,Tue,Wed,Thu,Fri','Daily'),
('117 West 17th Street','Water Filter Change & Roof Drain Check','10','11','','Bi-Monthly'),
('112 West 18th Street','Water Filter Change & Roof Drain Check','11','12','','Bi-Monthly'),
('135–139 West 17th','Backyard Drain Check','10','10','Fri','Weekly'),
('131 Perry Street','Boiler Blow-Down','8','8','Wed','Weekly'),
('138 West 17th Street','Boiler Blow-Down','10','10','Thu','Weekly'),
('135–139 West 17th','Boiler Blow-Down','10','10','Tue','Weekly'),
('117 West 17th Street','Boiler Blow-Down','11','11','Tue','Weekly'),
('104 Franklin','Sidewalk Hose','7','7','Mon,Wed,Fri','Weekly'),
('36 Walker','Sidewalk Sweep','7','8','Mon,Wed,Fri','Weekly'),
('41 Elizabeth Street','Bathrooms Clean','8','9','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('41 Elizabeth Street','Lobby & Sidewalk Clean','9','10','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('41 Elizabeth Street','Elevator Clean','10','11','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('41 Elizabeth Street','Afternoon Garbage Removal','13','14','Mon,Tue,Wed,Thu,Fri,Sat','Daily'),
('41 Elizabeth Street','Deliver Mail & Packages','14','14','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Evening Garbage Collection','18','19','Mon,Wed,Fri','Weekly'),
('68 Perry Street','DSNY Prep / Move Bins','19','20','Mon,Wed,Fri','Weekly'),
('123 1st Ave','DSNY Prep / Move Bins','19','20','Tue,Thu','Weekly'),
('104 Franklin','DSNY Prep / Move Bins','20','21','Mon,Wed,Fri','Weekly'),
('135–139 West 17th','Evening Building Security Check','21','22','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Sidewalk & Curb Clean','9','10','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Lobby & Vestibule Clean','10','11','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Glass & Elevator Clean','11','12','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Trash Area Clean','13','14','Mon,Tue,Wed,Thu,Fri','Daily'),
('12 West 18th Street','Boiler Blow-Down','14','14','Fri','Weekly'),
('12 West 18th Street','','','','',''),
('117 West 17th Street','Boiler Blow-Down','9','11','Mon','Weekly'),
('133 East 15th Street','Boiler Blow-Down','11','13','Tue','Weekly'),
('136 West 17th','Boiler Blow-Down','13','15','Wed','Weekly'),
('138 West 17th Street','Boiler Blow-Down','15','17','Thu','Weekly'),
('115 7th Ave','Boiler Blow-Down','9','11','Fri','Weekly'),
('112 West 18th Street','HVAC System Check','9','12','','Monthly'),
('117 West 17th Street','HVAC System Check','13','16','','Monthly');

-- End of routine_tasks

INSERT INTO workers ("id","name","email","role","passwordHash","skillLevels","assignedBuildings","timezonePreference") VALUES
('1','Greg Hutson','g.hutson1989@gmail.com','worker','','["plumbing"','electrical','hvac]'),
('2','Edwin Lema','edwinlema911@gmail.com','worker','','["cleaning"','sanitation','inspection]'),
('4','Kevin Dutan','dutankevin1@gmail.com','worker','','["hvac"','electrical','technical]'),
('5','Mercedes Inamagua','Jneola@gmail.com','worker','','["cleaning"','sanitation]','["1"'),
('6','Luis Lopez','luislopez030@yahoo.com','worker','','["maintenance"','manual','inspection]'),
('7','Angel Guirachocha','lio.angel71@gmail.com','worker','','["cleaning"','sanitation','manual]'),
('8','Shawn Magloire','shawn@francomanagementgroup.com','worker','','["management"','inspection','maintenance');

-- End of workers

INSERT INTO buildings ("id","name","address","imageAssetName","latitude","longitude") VALUES
('1','12 West 18th Street','12 W 18th St, New York, NY','12_West_18th_Street','',''),
('2','29-31 East 20th Street','29-31 E 20th St, New York, NY','29_31_East_20th_Street','',''),
('3','36 Walker Street','36 Walker St, New York, NY','36_Walker_Street','',''),
('4','41 Elizabeth Street','41 Elizabeth St, New York, NY','41_Elizabeth_Street','',''),
('5','68 Perry Street','68 Perry St, New York, NY','68_Perry_Street','',''),
('6','104 Franklin Street','104 Franklin St, New York, NY','104_Franklin_Street','',''),
('7','112 West 18th Street','112 W 18th St, New York, NY','112_West_18th_Street','',''),
('8','117 West 17th Street','117 W 17th St, New York, NY','117_West_17th_Street','',''),
('9','123 1st Avenue','123 1st Ave, New York, NY','123_1st_Avenue','',''),
('10','131 Perry Street','131 Perry St, New York, NY','131_Perry_Street','',''),
('11','133 East 15th Street','133 E 15th St, New York, NY','133_East_15th_Street','',''),
('12','135-139 West 17th Street','135-139 W 17th St, New York, NY','135West17thStreet','',''),
('13','136 West 17th Street','136 W 17th St, New York, NY','136_West_17th_Street','',''),
('14','Rubin Museum (142-148 W 17th)','142-148 W 17th St, New York, NY','Rubin_Museum_142_148_West_17th_Street','',''),
('15','Stuyvesant Cove Park','20 Waterside Plaza, New York, NY 10010','Stuyvesant_Cove_Park','',''),
('16','138 West 17th Street','138 W 17th St, New York, NY','138West17thStreet','','');

-- End of buildings

INSERT OR REPLACE INTO app_settings (key,value) VALUES ('csv_checksum','84c394cdd7343406822647231843acf1d05d12986bd699dac02a032370b9e2ec');
COMMIT;
