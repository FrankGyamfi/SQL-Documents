-- "Welcome to my first SQL project. I have obtained a call center data from the internet, which is available for data analyst
--newbies to practice. Therefore, I am using this data to practice the SQL queries I have learned that relates to this data during my studies.
--Let's get started!

-- The first thing is to have an overview of the data in SQL
--Line 1
Select *
from dbo.[Call Center Info];

--Upon viewing this table, I realised a particular column was empty therefore I would start by first removing it

--Line 2
Use [SQL Tutorial]
	Alter table [Call center Info] 
		drop column f4;

-- Secondly, the call_timestamp had unnecessary '00:00:00:000' attached to them. Therefore I would make the column a date format

--Line 3
Update [Call Center Info]
	set call_timestamp=CAST(call_timestamp as date);

-- I realised that though this command was successful, the display of the date did not change in the table therefore I used the alter table
-- function

--Line 4
Alter table [Call center info]
	alter column [call_timestamp] date;

-- Finally it worked, so now I am changing the name of the column from call_timestamp to CallDate

--Line 5
sp_rename '[Call center info].[call_timestamp]','Calldate', 'COLUMN';

--I then moved to the next table "customer details" to have a look at it

--Line 6
Select *
from dbo.[Customer Details];

--The table looked okay but had some a bit of trim issues with customer name so i used the trim function

--Line 7
Update [Customer Details]
set customer_name=TRIM(customer_name);

--The customer_name seemed okay at this point so I am moving to the next table "customer location"

--Line 8
Select*
from dbo.[Customer Location];

--The table seem okay so onto the next table "customer satisfaction"

--Line 9
Select*
from dbo.[Customer Satisfaction];

--In this table, everything looked okay except for the column csat_score where there were nulls. Therefore i would replace the null with N/A.

--Line 10
Update [Customer Satisfaction]
	Set csat_score='N/A'
	Where csat_score is null;

-- I first tried tried this query and had a data type related error therefore i tried to identify the data type of the column

--Line 11
Select DATA_TYPE
	from INFORMATION_SCHEMA.COLUMNS
	Where TABLE_NAME='Customer Satisfaction'
	and COLUMN_NAME='csat_score';

--The query showed that the data type was float therefore i decided to change the column's data type and 
--use the case statement to write the update query again

--Line 12
Alter table [Customer Satisfaction]
	Alter Column csat_score varchar(50);

--Line 13
Update [Customer Satisfaction]
	set csat_score=Case 
						When csat_score=' ' or csat_score Is Null
						Then 'N/A' 
						Else csat_score
					End;

--Also, i realised the table had a customer satisfaction as column though customer satisfaction was its name too. 

--Line 14
sp_rename '[customer satisfaction].[customer satisfaction]','Satisfaction Rating';
	
--Having cleaned the data it was now time to gather some insights from the tables.

--The first thing I wanted to know was the average satisfaction rate of the customers and its implied sentiment.

--Line 15
Select round(AVG([satisfaction rating]),0) as [Average Satisfaction Rating],
	Case
		When Round(AVG([satisfaction rating]),0)=1 then 'Very Positive'
		When Round(avg([satisfaction rating]),0)=2 then 'Positive'
		When Round(avg([satisfaction rating]),0)=3 then 'Neutral'
		When Round(avg([satisfaction rating]),0)=4 then 'Negative'
		When Round(avg([satisfaction rating]),0)=5 then 'Very Negative'
	End as 'Sentiment'
from dbo.[Customer Satisfaction];

--Knowing the average satisfaction rating I decided to create a view for it.

--Line 16
Drop view if exists [Average Customer Satisfaction Rating];

--Line 17
Create view [Average Customer Satisfaction Rating] 
AS
	Select round(AVG([satisfaction rating]),0) as [Average Satisfaction Rating],
	Case
		When Round(AVG([satisfaction rating]),0)=1 then 'Very Positive'
		When Round(avg([satisfaction rating]),0)=2 then 'Positive'
		When Round(avg([satisfaction rating]),0)=3 then 'Neutral'
		When Round(avg([satisfaction rating]),0)=4 then 'Negative'
		When Round(avg([satisfaction rating]),0)=5 then 'Very Negative'
	End as 'Sentiment'
from dbo.[Customer Satisfaction];

--I then decided to have an overview of the sentiments among customers

--Line 18
Select distinct(sentiment), count(sentiment) over (partition by sentiment) as [Count of Sentiment]
	From [Customer Satisfaction]
	Order by [Count of Sentiment] desc;

--Having gathered the insighted i decided to create a view for that as well

--Line 19
Drop view if exists [Customer Sentiments];

--Line 20
Create view [Customer Sentiments]
AS
Select distinct(sentiment), count(sentiment) over (partition by sentiment) as [Count of Sentiment]
From [Customer Satisfaction];

-- Now i wanted to check for the days where calls were at its peak

--Line 21
Select distinct top 10 (convert(varchar(2), day(calldate))+ 
	Case
		When DAY(calldate) in (1,31,21) then 'st'
		When DAY(calldate) in (3,23) then 'rd'
		When day(calldate) in (2, 22) then 'nd'
			Else 'th'
	End + ' ' + DateName(MONTH, calldate)), count(Calldate) as [Number of calls]
from [Call Center Info] 
group by Calldate
Order by [Number of calls] desc;


--I went on to create a view for this as well

--Line 22
Create view [Peak Call Days]
AS
Select distinct top 10 (convert(varchar(2), day(calldate))+ 
	Case
		When DAY(calldate) in (1,31,21) then 'st'
		When DAY(calldate) in (3,23) then 'rd'
		When day(calldate) in (2, 22) then 'nd'
			Else 'th'
	End + ' ' + DateName(MONTH, calldate)) as [Date], count(Calldate) as [Number of calls]
from [Call Center Info] 
Group by Calldate;

--Having found the peak call days i wanted to have an overview of the reasons why most customers reached out

--Line 23
Select reason as Reason, count(reason) as [Number of Calls]
from [Call Center Info]
Group by reason
Order by [Number of Calls] desc;

--Line 24
Drop view if exists [Call Reasons];

--Line 25
 Create View [Call Reasons]
 AS
 Select reason as Reason, count(reason) as [Number of Calls]
from [Call Center Info]
Group by reason;

--At this point I wanted have an overview of the states and the number of calls from each

--Line 26
Select state as State, Count(state) as [Number of Calls]
From [Customer Location]
Group by state
Order by [Number of Calls] desc;

--I then went ahead to create a view for it

--Line 27
Drop view if exists [Top 10 States];

--Line 28
Create View [States by Call]
AS
Select state as State, Count(state) as [Number of Calls]
From [Customer Location]
Group by state;

--At this point I had some questions but i realised I can only get the answer by combining the customer location table
-- to the call center info table.

--Line 29
Select City, State, Reason, Channel, Call_Center, response_time
From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id;

-- In order to query off this table i decided to create a temp table here

--Line 30
Create table [#Location_Call Centre]
	(City varchar (50), State varchar (50), 
	Reason varchar(50), Channel varchar(50), 
	Call_Centre varchar(50), Response_time varchar(50));

--At this point I inserted the values from the join table into the temptable

--Line 31
Insert into [#Location_Call Centre]
Select City, State, Reason, Channel, Call_Center, response_time
From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id;

--Having successfully joined and inserted the data, I wanted to zoom in further and know the top 10 cities and their reasons for calling

--Line 32
Select distinct top 10 City, count(city) [Number of Calls], Reason
from [#Location_Call Centre]
group by City, Reason
order by [Number of Calls] desc;

--After that i decided to create a view for it

--Line 33
Create View [Top 10 Cities]
AS
Select distinct top 10 City, count(city) [Number of Calls], Reason
From [#Location_Call Centre]
Group by City, Reason;

--I was then prompted that views are not allowed on temporary tables so I resorted to creating a CTE instead

--Line 34
With locationcall
As
(Select City, State, Reason, Channel, Call_Center, response_time
From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id)
	
	Select distinct top 10 City, count(city) [Number of Calls], max(Reason) as [Call Reason]
from locationcall
group by City
order by [Number of Calls] desc;

--I then proceeded to creating a view for it

--Line 35
Create view [Top 10 Cities]
AS
	With locationcall As
(Select City, State, Reason, Channel, Call_Center, response_time
	From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id)

select distinct top 10 City, count(city) as [Number of Calls], Reason
from locationcall
group by City, Reason;

--At this point, I was interested in having an overview of the channels used by customers.

--Line 36
Select channel, count(channel) as [Number of Calls]
from [Call Center Info]
Group by channel
Order by [Number of Calls] desc;

--I created a view for that as well

--Line 37
Drop view if exists [Channel Ranking];

--Line 38
Create View [Channel Ranking]
AS
Select channel as Channel, count(channel) as [Number of Calls]
from [Call Center Info]
Group by channel;

--Now I wanted to check the average number minutes customers spent reaching out from each state and the 
--Sum of calls by state

--Line 39
With locationcall
As
(Select City, State, Reason, Channel, Call_Center, response_time, [call duration in minutes]
From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id)
	Select Distinct state as State, 
		Sum([call duration in minutes]) as [Total Minutes (mins)],
		Round(avg([call duration in minutes]),0) as [Average Duration (mins)]
From locationcall
Group by state
Order by [Total Minutes (mins)] desc;

--Line 40
Drop view if exists [Minutes by State]

--Line 41
Create View [Minutes by State]
AS
With locationcall
As
(Select City, State, Reason, Channel, Call_Center, response_time, [call duration in minutes]
From [Customer Location] as CL join dbo.[Call Center Info] as CC on CL.id=CC.id)
	
	select distinct state as State,
		sum([call duration in minutes]) as [Total Minutes (mins)],
		Round(avg([call duration in minutes]),0) as [Average Duration (mins)]
from locationcall
group by state;

--Now I wanted to have an overview of about the use of call channels and their response time based
--Service level agreement (SLA)

--Line 42
With [Channels]
AS
(
	Select call_center as [Call Centre],response_Time as [Response Time],
		COUNT(call_center) as [Number of Calls],ROW_NUMBER () over (partition by call_center order by count(*) desc) as [Ranking]
From [Call Center Info]
Group by call_center,response_time
)
Select [Call Centre],[Response Time]
from Channels
where Ranking=1;

-- I went on to create a view for it

--Line 43
Drop view if exists [Use of Call Channels];

--Line 44
Create View [Use of Call Channels]
AS
	With [Channels]
	AS
(
	Select call_center as [Call Centre],response_Time as [Response Time],
		COUNT(call_center) as [Number of Calls],ROW_NUMBER () over (partition by call_center order by count(*) desc) as [Ranking]
From [Call Center Info]
Group by call_center,response_time
)
Select [Call Centre],[Response Time]
from Channels
where Ranking=1;


--Finally, I wanted to have an overview of the call minutes and reasons at the various call centres

--Line 45
With Cte AS
(
	Select call_center, reason, COUNT(*) as [Total Count],
		ROW_NUMBER() over (partition by call_center order by count(*) desc) as [Rank],
		SUM([call duration in minutes]) as [Total Minutes],
		ROUND(AVG([call duration in minutes]),0) as [Average Minutes]
From [Call Center Info]
Group by call_center,reason
)
	Select call_center, reason, [Total Minutes], [Average Minutes]
	from Cte
	where [Rank]=1
	Order by [Total Minutes] desc;

--Line 46
Drop view if exists [Call Center Minutes and Reasons];

--Line 47
Create View [Call Center Minutes and Reasons]
AS
With Cte AS
(
	Select call_center as [Call Center], reason as [Reason], COUNT(*) as [Total Count],
		ROW_NUMBER() over (partition by call_center order by count(*) desc) as [Rank],
		SUM([call duration in minutes]) as [Total Minutes],
		ROUND(AVG([call duration in minutes]),0) as [Average Minutes]
From [Call Center Info]
Group by call_center,reason
)
	Select [Call Center], [Reason], [Total Minutes], [Average Minutes]
	from Cte
	where [Rank]=1;


--This is the end of the my call center data SQL project

--Declaration
--I declare that this project is of my own hand based on research and previous knowledge gathered in the course of my SQL studies.


