The following uploading programs generalsites.rb, generalcultivars.rb and generalyields.rb are a much more general uploader of datafiles. These should work for almost any data file as long as it has the appropriate data columns. The order of the columns doesn't make a different as long as it has the columns and the data the program should successfully find the data and upload it. 

Instructions of use:
1. First install the following gems necessary to run the programs
	-mysql, mysql2
	ex:
	gem install mysql 
2. Then open up uploadsites.rb
3. Change the server details of each file uploadsites, uploadcovariates,uploadyields to those specific to your server settings
	Ex:
	con = Mysql.new 'localhost','root','password','bety' 
	It should also prompt you of these details.
4. Change the filename you read the data from to the proper file
  	Ex:
	CSV.foreach('sugarcanesites.csv')
5. open up a commandline and type ruby [nameofthescript]
    Ex:
 	ruby uploadsites.rb 
	ruby uploadcovariates.rb
	ruby uploadyields.rb

