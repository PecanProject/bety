#include <my_global.h>
#include <mysql.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv){
	MYSQL *conn;
	MYSQL_RES *result;
	MYSQL_ROW row;	
	int num_fields;
	int i;
	FILE *outfile;
	MYSQL *tablecomments;
	MYSQL_RES *tcresult;
	MYSQL_ROW tcrow;
	outfile= fopen("tables.txt","w");
	conn= mysql_init(NULL);
	tablecomments=mysql_init(NULL);
	FILE *tablecommentsfile;
	tablecommentsfile=fopen("comments.csv","w");
	if (outfile==NULL)
		printf("file doesn't exist\n");
	if (conn==NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	if (mysql_real_connect(conn,"localhost","bety","bety","bety",0,NULL,0)== NULL){
		printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
		exit(1);
	}
	mysql_query(conn, "show tables");
	result=mysql_store_result(conn);
	num_fields=mysql_num_fields(result);
	while ((row=mysql_fetch_row(result))){
		for (i=0; i<num_fields;i++){
			fprintf(outfile,"%s\n",row[i]);
			printf("%s",row[i]);
		}
		printf("\n");
	}
	mysql_free_result(result);
	if (mysql_real_connect(tablecomments,"localhost","bety","bety","INFORMATION_SCHEMA",0,NULL,0) == NULL){
			printf("Error %u: %s\n",mysql_errno(conn),mysql_error(conn));
			exit(1);
	}
	mysql_query(tablecomments,"SELECT DISTINCT TABLE_NAME,TABLE_COMMENT FROM TABLES WHERE TABLE_SCHEMA=\"BETY\"");
	tcresult=mysql_store_result(tablecomments);
	num_fields=mysql_num_fields(tcresult);
	fprintf(tablecommentsfile,"The Tables of the Database \n Table Name , Comment \n");
	while ((tcrow=mysql_fetch_row(tcresult))){
		for (i=0; i<num_fields;i++){
			fprintf(tablecommentsfile,"%s,",tcrow[i]);
		}
		fprintf(tablecommentsfile,"\n","");
	}
}