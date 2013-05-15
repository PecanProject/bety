require 'csv'
require 'mysql'
begin
   puts "Please type the hosting service of the database: Default is localhost"
   host=gets.chomp
   puts "type the username to connect to your database\n"
   username=gets.chomp
   puts "please type the password"
   password=gets.chomp
   puts "please type the name of the database"
   database=gets.chomp
   con = Mysql.new("#{host}","#{username}","#{password}","#{database}")
   mtempquery= "CREATE TABLE temp(name VARCHAR(25), id INT(11))"
 	 con.query(mtempquery)     #creating a temporary table to store the ids.
   linecounter=0
   items = Array.new(8){Array.new(3)}
   items[0][0]="id" # initialize an array of the items you need to find
   items[1][0]="city"
   items[2][0]="state"
   items[3][0]="country"
   items[4][0]="lat"
   items[5][0]="lon"
   items[6][0]="soil"
   items[7][0]="sitename"
   linecounter=0;
   	CSV.foreach('sugarcanesites.csv') do |row| 
   	  #puts "linecounter #{linecounter}\n"
   	  if linecounter==0
   	    i=0;
   	    while i<22 #find the columns of the items you need to find
   	      t=0
   	      while t<8
   	        if row[i]==items[t][0]
   	          #puts "row = #{i} the item inside = #{row[i]}\n"
   	          items[t][1]=i;
   	         # puts "item[t] t=#{t} the item inside #{items[t][1]}\n"
   	          break
   	        else
   	          t+=1
   	        end
   	       
   	      end
   	      i+=1
   	      #puts "#{i}"
   	    end
   	     
   	      linecounter=linecounter+1
     	    #puts "linecounter #{linecounter}\n"
   	    if items[0][1]==nil
   	      puts "no id column in file"
   	      exit
   	    end
 	      if items[1][1]==nil
     	    puts "no city column in file"
     	    exit
     	  end
     	  if items[2][1]==nil
       	    puts "no state column in file"
       	    exit
       	end
       	if items[3][1]==nil
       	    puts "no country column in file"
       	    exit
       	end
       	if items[4][1]==nil
       	    puts "no lat column in file"
       	    exit
       	end
       	if items[5][1]==nil
       	    puts "no lon column in file"
       	    exit
       	end
       	if items[6][1]==nil
       	    puts "no soil column in file"
       	    exit
       	end
       	if items[7][1]==nil
       	    puts "no sitename column in file"
       	    exit
       	end
   	  else #get the value of the items you need to find
   	    items[0][2]=row[items[0][1]]#id
     	  items[1][2]=row[items[1][1]]#city
     	  items[2][2]=row[items[2][1]]#state
     	  items[3][2]=row[items[3][1]]#country
     	  items[4][2]=row[items[4][1]]#lat
     	  items[5][2]=row[items[5][1]]#lon
     	  items[6][2]=row[items[6][1]]#soil
     	  items[7][2]=row[items[7][1]]#sitename
   	    query="INSERT INTO sites(city, state, country, lat, lon, mat, map, masl, soil, som, notes, soilnotes,
        created_at, updated_at, sitename, greenhouse)
        VALUES ('#{items[1][2]}', '#{items[2][2]}','#{items[3][2]}', '#{items[4][2]}', '#{items[5][2]}'
        ,NULL,NULL,NULL, '#{items[6][2]}',NULL,NULL,NULL,NULL,NULL, '#{items[7][2]}', NULL)"
         puts "linecounter=#{linecounter}  city = #{items[1][2]} state= #{items[2][2]} country= #{items[3][2]} lat=#{items[4][2]}\n"
   	     puts "lon=#{items[5][2]} soil=#{items[6][2]} sitename=#{items[7][2]}\n"
   	     con.query(query)
   	     idquery="SELECT id FROM sites where lon=#{items[5][2]} AND lat=#{items[4][2]} AND sitename='#{items[7][2]}' AND state='#{items[2][2]}'"
   	     idresult=con.query(idquery)
         number=0;
         idresult.each_hash do |site|
           number=site['id']
         end
         tempquery="INSERT INTO temp(name,id) VALUES('#{items[0][2]}',#{number})"   # add stuff to temporary database.
         con.query(tempquery)
         linecounter=linecounter+1
       end
      end
  rescue Mysql::Error => e
        puts e.errno
        puts e.error

  ensure
        con.close if con
end