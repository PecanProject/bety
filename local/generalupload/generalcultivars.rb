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
   #maketbquery= con.query 'CREATE TABLE tempcultivar(name VARCHAR(25),id INT(11))'
   linecounter=0
   items=Array.new(2){Array.new(3)} #initialize the items you need to find
   items[0][0]="specie_id"
   items[1][0]="name"
   	CSV.foreach('sugarcanecultivars.csv') do |row| 
   	   if linecounter==0 
     	    i=0;
     	    z=row.length
     	    while i<z
     	      t=0
     	      while t<2 #find the columns of the items you need to find
     	        if row[i]==items[t][0]
     	          #puts "row = #{i} the item inside = #{row[i]}\n"
     	          items[t][1]=i;
     	          #puts "item[t] t=#{t} the item inside #{items[t][1]}\n"
     	          break
     	        else
     	          t+=1
     	        end

     	      end
     	      i+=1
     	      #puts "#{i}"
     	    end
     	    linecounter=linecounter+1
     	    if items[0][1]==nil
     	      puts "no specie_id column in file"
     	      exit
     	    end
   	      if items[1][1]==nil
       	    puts "no name column in file"
       	    exit
       	  end
       	else #get the value of the items you need to find
       	  items[0][2]=row[items[0][1]]#specie_id
       	  items[1][2]=row[items[1][1]]#name
       	  query = "INSERT INTO cultivars(specie_id, name, ecotype, notes, created_at, updated_at, previous_id)
  		    VALUES(#{items[0][2]}, '#{items[1][2]}' , NULL, NULL, NULL, NULL, NULL)"
  		    puts "specie_id= #{items[0][2]} name= #{items[1][2]}"
  		    con.query(query)
  		     idquery="SELECT id FROM cultivars WHERE specie_id='#{items[0][2]}' AND name='#{items[1][2]}'" # add them to the respective databases
    		    idresult=con.query(idquery);
            number=0;
            idresult.each_hash do |site|
              number=site['id']
            end
            tempcultquery="INSERT INTO tempcultivar(name,id) VALUES('#{items[1][2]}', '#{number}')" # 
    		    con.query(tempcultquery)
    		    linecounter=linecounter+1
        end
      end
  rescue Mysql::Error => e
          puts e.errno
          puts e.error

  ensure
      con.close if con
end