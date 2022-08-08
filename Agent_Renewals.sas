/* First import the salesperson list and the broker list I've downloaded from the CT eLicense Portal:
https://www.elicense.ct.gov/Lookup/GenerateRoster.aspx */
PROC IMPORT OUT= WORK.sales
            DATAFILE= "C:\Users\tsessions\Downloads\Real_Estate_Salespersons.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

PROC IMPORT OUT= WORK.brokers 
            DATAFILE= "C:\Users\tsessions\Downloads\Real_Estate_Brokers.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/* Next import the list of all agents that have and have not renewed their licenses. */

PROC IMPORT OUT= WORK.wpsir 
            DATAFILE= "C:\Users\tsessions\Downloads\2022 WPSIR Litchfield Hills - License Renewals.xlsx" 
            DBMS=EXCEL REPLACE;
     GETNAMES=YES;
RUN;

/* drop unnecessary column from salesperson data */
data sales;set sales;
drop var13 Supervisor_Credential__ Supervision;run;

/* set id variable to the same name for to append to sales data. also more data management */
data brokers;set brokers;
rename REGISTRATION=LICENSE;
drop BUSINESS_NAME var12; RUN;

data roster;set sales brokers; /* appends salesperson data and brokers */
where license ne '';run; /*drops agents with a blank license id cell */

data wpsir;set wpsir;
drop f15;run; /*unnecessary column */

/*sort wpsir agents and ct roster by the id variable after standardizing name to LICENSE_NO_*/
data roster;set roster;
rename LICENSE = LICENSE_NO_;run;

proc sort data=wpsir;
by LICENSE_NO_;run;

proc sort data=roster;
by LICENSE_NO_;run;

/*inner join of the wpsir agent list with ct roster */
data matched; merge roster wpsir; by LICENSE_NO_;run;

/*removes data with missing information */
data matched;set matched;
if AGENT_FIRST ne '';run;

/*drop duplicate columns */
data matched;set matched;
drop FIRST_NAME LAST_NAME AGENT_STREET AGENT_CITY AGENT_STATE AGENT_ZIP AGENT_STATUS F16 F17 F18 F19 F20 F21 F22 F23 F24 F25 F26 F27 F28 F29;run;

/*checks if agent's license expires in 2022 or 2023. if it expires in 2022, they haven't renewed yet. if it expires in 2023, they have. */
data matched; set matched;
format EXPIRATION_DATE mmddyy10.;
if EXPIRATION_DATE<'01JAN2023'd then LICENSE_RENEWAL="N";
if EXPIRATION_DATE>'01JAN2023'd then LICENSE_RENEWAL="Y";
if AGENT_LAST eq "BOLLARD" then LICENSE_RENEWAL="Y";
DROP EFFECTIVE_DATE EXPIRATION_DATE LAST_NAME;RUN;

proc sort data=matched nodupkey;by LICENSE_NO_;run; /*removes any duplicate agents */
proc sort data=matched;by LICENSE_RENEWAL;RUN; /*sorts new dataset by renewal status */

/*makes the spreadsheet presentable with a clear flow of columns */
data matched;
format LICENSE_RENEWAL office agent_first agent_last agent_name address city state zip LICENSE_NO_ status LICENSE_START LICENSE_EXPIRATION FIRM;
set matched;run;

/*export the spreadsheet */
PROC EXPORT DATA= WORK.matched 
            OUTFILE= "C:\Users\tsessions\Desktop\agentrenewals.xls" 
            DBMS=EXCEL LABEL REPLACE;
     SHEET="agentrenewals"; 
RUN;
