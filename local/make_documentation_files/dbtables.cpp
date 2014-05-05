/* 
* compile with g++ [file_name.cpp] -lpqxx -lpq -o [exec_name]
* execute with ./[exec_name]  
*/
#include<iostream>
#include<fstream>
#include<pqxx/pqxx>
#include<typeinfo>
#define OUT_FILE "test.html"
using namespace std;
using namespace pqxx;
int main(int argc, char** args){
	string DB= "bety";			
 	string USER= "carya";				
	string PASSWORD= "illinois";	
	string HOST = "127.0.0.1";		
	string PORT = "5432";
	string connstr=	"dbname="+DB+" user="+USER+" password="+PASSWORD+" \
      hostaddr="+HOST+" port=" + PORT;
    connection conn(connstr);
	work w(conn);
	fstream outfile(OUT_FILE,ios::out);
	if(!outfile.is_open()){
		cout<<"file error"<<endl;
		return 0;
	}
	outfile<<"<html>"<<endl;
	string oidquery="SELECT c.oid,c.relname FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace where pg_catalog.pg_table_is_visible(c.oid) and c.relkind='r' and n.nspname='public'";
	result oids=w.exec(oidquery);
	string query="SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod),pg_catalog.col_description(a.attrelid, a.attnum) as comments FROM (pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace) join pg_catalog.pg_attribute a on a.attrelid =c.oid where pg_catalog.pg_table_is_visible(c.oid) and c.relkind='r' and n.nspname='public' and  a.attnum > 0 AND NOT a.attisdropped and a.attrelid=";
	for(int i=0; i<oids.size();i++){
		outfile<<"<table border=1 cellpadding=5 cellspacing=5>"<<endl;
		string oid=oids[i][0].c_str();
		string tablenamequery="SELECT c.relname FROM pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace where c.oid="+oid;
		result name=w.exec(tablenamequery);
		outfile<<"<tr><th colspan='3'>"<<name[0][0].c_str()<<"</th><tr>"<<endl;
		outfile<<"<tr><th>col_name</th><th>col_type</th><th>col_comment</th></tr>"<<endl;
		result cols=w.exec(query+oid);
		for(int j=0;j<cols.size();j++){
			int s=cols[j].size();
			outfile<<"<tr>"<<endl;
			for(int k=0;k<s;k++)
				outfile<<"<td>"<<cols[j][k].c_str()<<"</td>"<<endl;
			if(s<3) outfile<<"<td>""</td>"<<endl;
			outfile<<"<tr>"<<endl;
		}
		outfile<<"</table><br>"<<endl;
	}
	outfile<<"</html>"<<endl;
	outfile.close();
	w.commit();
	return 0;
	
}
