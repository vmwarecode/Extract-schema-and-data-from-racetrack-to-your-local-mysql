
#/**
# Used to extract schema and data from racetrack to your local mysql.
#
#Created by dni@vmware.com on 4/3/16/3/16
#/

# connection of Racetrack 
racetrack_database_server_name==<racetrack server name>
racetrack_database_name==<racetrack database name>
racetrack_database_user==<user>
racetrack_database_password=<password>

# connection of local mysql  
automation_database_server_name=<local server name>
automation_database_name=<local database name>
automation_database_user=<user>
automation_database_password=<password>

g11n_automation_execution_testset=G11N_Automation_Execution_TestSet
g11n_automation_execution_testsetdata=G11N_Automation_Execution_TestSetData
g11n_automation_execution_testcase=G11N_Automation_Execution_TestCase

local_automationexecutiondb_backup_root_folder=../Database/$automation_database_name

function ExecutionSqlCommand()
{
	mysql --user=$automation_database_user --password=$automation_database_password $automation_database_name -e "$1"
}


function ExportAndImportData()
{
	full_sqlfile_name=$local_automationexecutiondb_backup_root_folder/Sql/$1.sql

	full_datafile_name=$local_automationexecutiondb_backup_root_folder/Data/Racetrack/$1.csv

	temp_datefile_name=$local_automationexecutiondb_backup_root_folder/Data/Racetrack/temp.csv

	
	#  export schema and data from Racetrack to csv
	table_name=$1\_Raw
	#export data from racetrack
	echo 'export data of '$table_name' from Racetrack'
	mysql --host=$racetrack_database_server_name --user=$racetrack_database_user --skip-secure-auth --password=$racetrack_database_password --database=$racetrack_database_name < $full_sqlfile_name > $full_datafile_name

	#make a copy of data and remove the header of column
	echo 'make a copy of data and remove the header of column'
	cp -rf 	$full_datafile_name $temp_datefile_name
	#remove the first row (column header)
	sed -i '1d' $temp_datefile_name


	#truncate table on local
	echo 'truncate table '$table_name' on '$automationexecutiondb_database_name
	command='truncate '$table_name
	ExecutionSqlCommand "$command"


	#import data to local
	echo 'import data of '$table_name' into '$automationexecutiondb_database_name
	command='load data local infile "'$temp_datefile_name'" into table '$table_name
	ExecutionSqlCommand "$command"

	#remove a copy of data
	echo 'remove a copy of data'
	rm -f $temp_datefile_name

}

interval=3600

while true
do
	ExportAndImportData $g11n_automation_execution_testset

	ExportAndImportData $g11n_automation_execution_testsetdata

	ExportAndImportData $g11n_automation_execution_testcase

	syncup_day=`date +%Y%m%d`
	syncup_time=`date +%H%M%S`

	echo 'The last syncup time was '$syncup_day'_'$syncup_time

	sleep $interval
done
