Instructions to use the upload sugarcane files
1. First install the following gems necessary to run the programs
	-mysql, mysql2
	ex:
	gem install mysql 
2. Then open up uploadstomata.rb
3. Change the filename you read the data from to the proper file
  	Ex:
	CSV.foreach('sugarcanesites.csv')
4. open up a commandline and type ruby [nameofthescript]
    Ex:
 	ruby uploadsites.rb 
	ruby uploadcovariates.rb
	ruby uploadyields.rb
5.When prompted enter in the appropriate server details into the terminal. Ex it will prompt serverhost: enter in localhost.
6.The data should be properly inserted to the database. If your line doesn't have a siteid like many of them do the rows that don't have it are listed line by line from the terminal.