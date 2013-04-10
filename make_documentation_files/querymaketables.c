#include <my_global.h>
#include <mysql.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>
using namespace std;
int main(){
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
	conn = mysql_init(NULL);
	if (conn==NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	if (mysql_real_connect(conn,"localhost","bety","bety","INFORMATION_SCHEMA",0,NULL,0)== NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	string tablename;
	fscanf(tablesfile,"%s",&tablename);
	while(tablename[0]!=EOF){
		string query;
		query="SELECT column_name,column_type,is_nullable,column_comment FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='";
		query=query+tablename;
		query =query +"'";
			mysql_query(conn,query.c_str());
			result=mysql_store_result(conn);
			num_fields=mysq_num_fields(result);
			string actualname;
			actualname=tablename;
			actualname=actualname+".csv";
			File *file;
			file=fopen(actualname.c_str(),"w");
			while ((tcrow=mysql_fetch_row(tcresult))){
				for (i=0; i<num_fields;i++){
					fprintf(file,"%s,",tcrow[i]);
				}
				fprintf(file,"\n","");
			}
	}
}	
