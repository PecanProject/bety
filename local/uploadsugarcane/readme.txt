Instructions to use the upload sugarcane files
1. First install the following gems necessary to run the programs
	-mysql, mysql2
	ex:
	gem install mysql 
2. Then open up uploadsites.rb
3. Change the server details of each file uploadsites, uploadcovariates,uploadyields to those specific to your server settings
	Ex:
	con = Mysql.new 'localhost','root','password','bety' 
4. Change the filename you read the data from to the proper file
  	Ex:
	CSV.foreach('sugarcanesites.csv')
5. open up a commandline and type ruby [nameofthescript]
    Ex:
 	ruby uploadsites.rb 
	ruby uploadcovariates.rb
	ruby uploadyields.rb
6. The data should be properly inserted to the database. If your line doesn't have a siteid like many of them do the rows that don't have it are listed line by line from the terminal.