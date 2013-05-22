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
   linecounter=0
   nosites=Array.new
   nositescounter=0
   items = Array.new(8){Array.new(3)}
   items[0][0]="citation_id"
   items[1][0]="site_id"
   items[2][0]="specie_id"
   items[3][0]="treatment_id"
   items[4][0]="cultivar_id"
   items[5][0]="date"
   items[6][0]="dateloc"
   items[7][0]="mean"
   CSV.foreach('sugarcaneyields.csv') do |row|
     if linecounter==0
  	    i=0;
  	    z=row.length
  	    while i<z #find the columns of the items you need to find
  	      t=0
  	      while t<8
  	        if row[i]==items[t][0]
  	          puts "row = #{i} the item inside = #{row[i]}\n"
  	          items[t][1]=i;
  	          puts "item[t] t=#{t} the item inside #{items[t][1]}\n"
  	          break
  	        else
  	          t+=1
  	        end
  	       
  	      end
  	      i+=1
  	      puts "#{i}"
  	    end
  	      linecounter=linecounter+1
  	    if items[0][1]==nil
  	        puts "no citation_id column in file"
  	        exit
  	    end
  	    if items[1][1]==nil
  	        puts "no site_id column in file"
  	        exit
  	    end
  	    if items[2][1]==nil
  	        puts "no specie_id column in file"
  	        exit
  	    end
  	    if items[3][1]==nil
  	        puts "no treatment_id column in file"
  	        exit
  	    end
  	    if items[4][1]==nil
  	        puts "no cultivar_id column in file"
  	        exit
  	    end
  	    if items[5][1]==nil
  	        puts "no date column in file"
  	        exit
  	    end
  	    if items[6][1]==nil
  	        puts "no dateloc column in file"
  	        exit
  	    end
  	    if items[7][1]==nil
  	        puts "no mean column in file"
  	        exit
  	    end
  	  else #get the value of the items you need to find
  	    items[0][2]=row[items[0][1]]#citation id
     	  tempsite=row[items[1][1]]#site id
     	  if tempsite!=nil
     	    siteidquery="SELECT id FROM temp WHERE name='#{tempsite}'"
    	    sidqresult=con.query(siteidquery)
    	    site_id=0;
    	    sidqresult.each_hash do |result|
    	      items[1][2]=result['id']
    	    end
        else
          items[1][2]=nil
        end
     	  items[2][2]=row[items[2][1]]#specie id
     	  items[3][2]=row[items[3][1]]#treatment id
     	  cid=row[items[4][1]]#cultivar id
     	  if (cid!=nil)
          cultivaridquery="SELECT id FROM tempcultivar WHERE name='#{cid}'"
          cultidresult=con.query(cultivaridquery)
          items[4][2]=0;
          cultidresult.each_hash do |result|
            items[4][2]=result['id']
          end
        else
          items[4][2]=0;
        end
     	  items[5][2]=row[items[5][1]]#date
     	  items[6][2]=row[items[6][1]]#dateloc
     	  items[7][2]=row[items[7][1]]#mean
     	  if (items[1][2]==nil)
     	    nosites[nositescounter]=linecounter;
     	    nositescounter+=1
     	    items[1][2]="NULL"
     	  end
     	  if (items[5][2]=='8/1/01')
     	    items[5][2]="08/01/2001"
     	  end
     	  if items[0][2]==nil
     	    items[0][2]="NULL"
     	  end
     	  if (items[2][2]==nil)
          puts "finished\n"
          break
        end
     	  query="INSERT INTO yields(citation_id, site_id, specie_id, treatment_id, cultivar_id, date, dateloc
        , statname, stat, mean, n, notes, created_at, updated_at, user_id, checked, access_level) 
        VALUES(#{items[0][2]}, #{items[1][2]}, '#{items[2][2]}', '#{items[3][2]}', #{items[4][2]}, #{items[5][2]}, #{items[6][2]}, NULL, NULL, #{items[7][2]}
        , NULL, NULL, NULL, NULL, NULL, NULL, NULL)"
        #puts "#{query}\n"
        con.query(query)
        linecounter+=1
      end
    end
    puts "the following entries have no site\n" 
    puts nosites
    con.query("DROP TABLE temp")
    con.query("DROP TABLE tempcultivar")
  rescue Mysql::Error => e
          puts e.errno
          puts e.error

  ensure
          con.close if con
end
     	  