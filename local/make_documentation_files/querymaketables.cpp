#include <my_global.h>
#include <mysql.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>
using namespace std;
int main(int argc, char** argv){
	MYSQL *conn;
	MYSQL_RES *result;
	MYSQL_ROW row;	
	int num_fields;
	int i;
	FILE *tablesfile;
	MYSQL *tablecomments;
	MYSQL_RES *tcresult;
	MYSQL_ROW tcrow;
	tablesfile=fopen("tables.txt","r");
	if (tablesfile==NULL)
		printf("failure to open tables");
	conn = mysql_init(NULL);
	if (conn==NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	if (mysql_real_connect(conn,"localhost","root","password","INFORMATION_SCHEMA",0,NULL,0)== NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	char stablename[35];
	while(fscanf(tablesfile,"%s",stablename)!=EOF){
		printf("got in first loop");
		string tablename(stablename);
		string query;
		query="SELECT column_name,column_type,is_nullable,column_comment FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='";
		query=query+tablename;
		query =query +"'";
			mysql_query(conn,query.c_str());
			result=mysql_store_result(conn);
			num_fields=mysql_num_fields(result);
			string actualname;
			actualname=tablename;
			actualname=actualname+".csv";
			FILE *file;
			file=fopen(actualname.c_str(),"w");
			if (file==NULL){
				printf("failure to createfiles \n");
			}
			while ((row=mysql_fetch_row(result))){
				for (i=0; i<num_fields;i++){
					fprintf(file,"%s,",row[i]);
				}
				fprintf(file,"\n","");
			}
			fclose(file);
	}
	return 0;
}	
