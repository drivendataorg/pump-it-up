libname lib "Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\pump_data";


/* importo i dati in SAS */
PROC IMPORT 
DATAFILE='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\pump_data\training_set.csv'
DBMS=dlm
OUT=lib.training_set
replace;
delimiter=',';
getnames=yes;

PROC IMPORT 
DATAFILE='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\pump_data\training_set_labels.csv'
DBMS=dlm
OUT=lib.training_labels
replace;
delimiter=',';
getnames=yes;


PROC IMPORT 
DATAFILE='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\pump_data\test_set_values.csv'
DBMS=dlm
OUT=lib.test_set
replace;
delimiter=',';
getnames=yes;


/* merge training set and training labels */
PROC SORT DATA=lib.training_set OUT=lib.training_set ;
  BY id ;
RUN ;

PROC SORT DATA=lib.training_labels OUT=lib.training_labels ;
  BY id ;
RUN ;


data lib.training_set;
   merge lib.training_set(in=A)
         lib.training_labels (in=B);
   by id;
   if A=B;
run;

/* add status group to test set <- the target!!! */
data lib.test_set;
	set lib.test_set;
	status_group  = '                       ';
run;

/* data exploring */

proc means data=lib.training_set n nmiss mean min max var;
run;

/* all good for continuos variables */

proc freq data = lib.training_set;  
run;


/* drop variables */
/* date recordder --> it is the test date of the waterpoint -> delete!!! */
/* remove duplicate variables */
data lib.training_set;
	set lib.training_set (drop=payment extraction_type_group waterpoint_type_group quantity_group scheme_name source_type water_quality public_meeting date_recorded wpt_name num_private region_code district_code recorded_by);
run;
data lib.test_set;
	set lib.test_set (drop=payment extraction_type_group waterpoint_type_group quantity_group scheme_name source_type water_quality public_meeting date_recorded wpt_name num_private region_code district_code recorded_by);
run;

data lib.test_set;
	set lib.test_set (drop=scheme_name wpt_name);
run;


/* transform variable - set missing!!! */


/* lower case */
data lib.training_set;
	set lib.training_set;
	funder = lowcase(funder);
	installer = lowcase(installer);
	basin = lowcase(basin);
	subvillage = lowcase(subvillage);
	region = lowcase(region);
	lga = lowcase(lga);
	ward = lowcase(ward);
	scheme_management = lowcase(scheme_management);
	extraction_type = lowcase(extraction_type);
	extraction_type_class = lowcase(extraction_type_class);
	management = lowcase(management);
	management_group = lowcase(management_group);
	payment_type = lowcase(payment_type);
	quality_group = lowcase(quality_group);
	quantity = lowcase(quantity);
	source = lowcase(source);
	source_class = lowcase(source_class);
	waterpoint_type = lowcase(waterpoint_type);
run;

data lib.test_set;
	set lib.test_set;
	funder = lowcase(funder);
	installer = lowcase(installer);
	wpt_name = lowcase(wpt_name);
	basin = lowcase(basin);
	subvillage = lowcase(subvillage);
	region = lowcase(region);
	lga = lowcase(lga);
	ward = lowcase(ward);
	scheme_name = lowcase(scheme_name);
	scheme_management = lowcase(scheme_management);
	extraction_type = lowcase(extraction_type);
	extraction_type_class = lowcase(extraction_type_class);
	management = lowcase(management);
	management_group = lowcase(management_group);
	payment_type = lowcase(payment_type);
	quality_group = lowcase(quality_group);
	quantity = lowcase(quantity);
	source = lowcase(source);
	source_class = lowcase(source_class);
	waterpoint_type = lowcase(waterpoint_type);
run;

data lib.training_set;
	set lib.training_set;

	if length(funder) = 0 or funder = '' then funder = .; else funder = funder;
	if length(installer) = 0 or installer = '' then installer = .; else installer = installer;
	if gps_height = 0 then gps_height = .; else gps_height = gps_height;
	if population = 0 then population = .; else population = population;
	if amount_tsh = 0 then amount_tsh = .; else amount_tsh = amount_tsh;
	if construction_year = 0 then construction_year = .; else construction_year = construction_year;

	/* transform latitude e longitude */
	if latitude = 0 then latitude = .; else latitude = latitude;
	if longitude = 0 then longitude = .; else longitude = longitude;
	
	if source = 'other' then source = .; else source = source;
run;

data lib.test_set;
	set lib.test_set;

	if length(funder) = 0 or funder = '' then funder = .; else funder = funder;
	if length(installer) = 0 or installer = '' then installer = .; else installer = installer;
	if gps_height = 0 then gps_height = .; else gps_height = gps_height;
	if population = 0 then population = .; else population = population;
	if amount_tsh = 0 then amount_tsh = .; else amount_tsh = amount_tsh;
	if construction_year = 0 then construction_year = .; else construction_year = construction_year;

	/* transform latitude e longitude */
	if latitude = 0 then latitude = .; else latitude = latitude;
	if longitude = 0 then longitude = .; else longitude = longitude;
	
	if source = 'other' then source = .; else source = source;
run;


/* input missing data */
data lib.training_set;
	set lib.training_set;
	if (funder = '') then funder='missing funder'; else funder = funder;
	if (installer = '') then installer='missing installer'; else installer = installer;
	if (subvillage = '') then subvillage='missing subvillage'; else subvillage = subvillage;
	if (scheme_management = '') then scheme_management='missing sc. management'; else scheme_management = scheme_management;
run;

data lib.test_set;
	set lib.test_set;
	if (funder = '') then funder='missing funder'; else funder = funder;
	if (installer = '') then installer='missing installer'; else installer = installer;
	if (subvillage = '') then subvillage='missing subvillage'; else subvillage = subvillage;
	if (scheme_management = '') then scheme_management='missing sc. management'; else scheme_management = scheme_management;

run;

/* modelli */




data lib.training_set_bin;
 set lib.training_set;
 if status_group = 'functional' then status_group_bin = 'no repare';
 if status_group = 'non functional' then status_group_bin = 'to repare';
 if status_group = 'functional needs repair' then status_group_bin = 'to repare';

run;


data lib.test_set_bin;
 set lib.test_set;
 status_group_bin = '                                            ';
run;


/* data exploration */

/* basin*/
proc sort data=lib.training_set_bin;
by basin;
run;

data basin;
	set lib.training_set_bin (keep=basin status_group_bin);
	by basin;
    if first.basin then count=0;
	count+1;

	if first.basin then c1=0;
	if first.basin then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.basin then output;
run;
data basin(drop=status_group_bin);
    set basin;
	odds = c0 / c1;

run;
proc sort data=basin;
by odds;
run;

/*payment type */
proc sort data=lib.training_set_bin;
by payment_type;
run;
data payment_type;
	set lib.training_set_bin (keep=payment_type status_group_bin);
	by payment_type;
    if first.payment_type then count=0;
	count+1;

	if first.payment_type then c1=0;
	if first.payment_type then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.payment_type then output;
run;
data payment_type(drop=status_group_bin);
    set payment_type;
	odds = c0 / c1;

run;
proc sort data=payment_type;
by odds;
run;
proc gchart data=lib.training_set_bin  ;
  title "Payment type" ;
  hbar payment_type /      
  subgroup=status_group_bin;
run;


/* quantity */
proc gchart data=lib.training_set_bin  ;
  title "Quantity" ;
  hbar quantity /      
  subgroup=status_group_bin;
run;
proc sort data=lib.training_set_bin;
by quantity;
run;
data quantity;
	set lib.training_set_bin (keep=quantity status_group_bin);
	by quantity;
    if first.quantity then count=0;
	count+1;

	if first.quantity then c1=0;
	if first.quantity then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.quantity then output;
run;
data quantity(drop=status_group_bin);
    set quantity;
	odds = c0 / c1;

run;
proc sort data=quantity;
by odds;
run;


/* source */
proc sort data=lib.training_set_bin;
by source;
run;
data source;
	set lib.training_set_bin (keep=source status_group_bin);
	by source;
    if first.source then count=0;
	count+1;

	if first.source then c1=0;
	if first.source then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.source then output;
run;
data source(drop=status_group_bin);
    set source;
	odds = c0 / c1;

run;
proc sort data=source;
by odds;
run;


/*management */
proc sort data=lib.training_set_bin;
by management;
run;
data management;
	set lib.training_set_bin (keep=management status_group_bin);
	by management;
    if first.management then count=0;
	count+1;

	if first.management then c1=0;
	if first.management then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.management then output;
run;
data management(drop=status_group_bin);
    set management;
	odds = c0 / c1;

run;
proc sort data=management;
by odds;
run;


/*management group*/
proc sort data=lib.training_set_bin;
by management_group;
run;
data management_group;
	set lib.training_set_bin (keep=management_group status_group_bin);
	by management_group;
    if first.management_group then count=0;
	count+1;

	if first.management_group then c1=0;
	if first.management_group then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.management_group then output;
run;
data management_group(drop=status_group_bin);
    set management_group;
	odds = c0 / c1;

run;
proc sort data=management_group;
by odds;
run;


/*ward*/
proc sort data=lib.training_set_bin;
by ward;
run;

data ward;
	set lib.training_set_bin (keep=ward status_group_bin);
	by ward;
    if first.ward then count=0;
	count+1;

	if first.ward then c1=0;
	if first.ward then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.ward then output;
run;
data ward(drop=status_group_bin);
    set ward;
	odds = c0 / c1;
    prob = c0 / (c0 + c1);
run;
proc sort data=ward;
by descending odds;
run;
proc sgplot data=ward(obs=10);
  title "Ward" ;
  vbar ward / response=odds;
run;
proc sort data=ward;
by odds;
run;
proc sgplot data=ward(obs=10);
  where odds>0;
  title "Ward" ;
  vbar ward / response=odds;
run;
proc export data=ward
   outfile='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\ward.csv'
   dbms=csv
   replace;
     delimiter=',';
run;
proc freq data=lib.training_set_bin;
	tables status_group_bin;
run;



/* check management */
proc sort data=lib.training_set_bin;
by ward;
run;

data ward_management;
	set lib.training_set_bin (keep=ward management status_group_bin);
	by ward;
    if first.ward then count=0;
	count+1;

	if first.ward then public=0;
	if first.ward then private=0;
	if first.ward then user=0;
	if first.ward then other=0;



	if management = 'trust' then private+1;
	if management = 'private operator' then private+1;
    if management = 'other' then other+1;
    if management = 'other - school' then public+1;
	if management = 'parastatal' then public+1;
	if management = 'wug' then user+1;
	if management = 'wua' then user+1;
	if management = 'water board' then public+1;
	if management = 'water authority' then public+1;
	if management = 'vwc' then user+1;
	if management = 'unknown' then other+1;


    if last.ward then output;
run;
data ward_management(drop=status_group_bin);
    set ward_management;
	user_perc = user / count;
    private_perc = private / count;
	public_perc = public / count;
run;
proc export data=ward_management
   outfile='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\ward_management.csv'
   dbms=csv
   replace;
     delimiter=',';
run;


proc sort data=lib.training_set_bin;
by ward;
run;

data ward;
	set lib.training_set_bin (keep=ward status_group_bin);
	by ward;
    if first.ward then count=0;
	count+1;

	if first.ward then c1=0;
	if first.ward then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

    if last.ward then output;
run;

data ward(drop=status_group_bin);
    set ward;
	odds = c0 / c1;
    prob = c0 / (c0 + c1);
run;


/* per mappa iniziale */
proc sort data=training_set_bin;
by ward;
run;

data ward_map;
	set lib.training_set_bin (keep=ward population status_group_bin);
	by ward;

	if first.ward then count=0;
		count+1;

	if first.ward then c1=0;
	if first.ward then total_pop=0;
	if first.ward then c0=0;
    if status_group_bin = 'no repare' then c1+1;
    if status_group_bin = 'to repare' then c0+1;

	total_pop+population;

    if last.ward then output;
run;


data ward_map;
	set ward_map;
	s = total_pop / count;
	s0 = total_pop / c0;
	s1 = total_pop / c1;
run;

proc export data=ward_map
   outfile='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\ward_map.csv'
   dbms=csv
   replace;
     delimiter=',';
run;







/* stepwise selection and difchi to find most importance variables and overlays*/

ods graphics on;
proc logistic data=lib.training_set_bin;
class 
status_group_bin (ref="to repare") waterpoint_type source quantity payment_type
extraction_type basin region ward management
/param=ref
;
model status_group_bin=
waterpoint_type source quantity payment_type
extraction_type basin region ward management
/selection=stepwise pevent=0.46 details lackfit;
output out=lib.training_set_bin_c DIFCHISQ=difchi ;    
run; quit;
ods graphics oFF;


proc means data=lib.training_set_bin_c n nmiss;
run;

data lib.training_set_bin_c; set pro_bin;
if difchi>=4; run;quit;


proc export data=lib.outlier
   outfile='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\outlier.csv'
   dbms=csv
   replace;
     delimiter=',';
run;


proc export data=lib.training_set_bin_c
   outfile='Y:\Desktop\Work\University\Master_BI_2016\Pump_it_waterpoint\training_set_bin.csv'
   dbms=csv
   replace;
     delimiter=',';
run;



