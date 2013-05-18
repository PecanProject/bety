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
 	linecounter=0;
 	#id, site_id, specie_id, citation_id, cultivar_id, treatment_id, date, dateloc, time,timeloc,mean, n, 
 	#statname,stat, notes,created_at, updated_at. variable_id, user_id, checked, access_level, entity_id, 
 	#method_id, date_year, date_month, date_day, time_hour, time_minute
 	CSV.foreach('stomatadata.csv') do |row|
 	  if (linecounter!=0)
 	    trait_id=row[0]
 	    if (trait_id==nil)
 	      trait_id="NULL"
 	    end
 	    #trait_id, citation_id, site_id, treatment_id, site, city, lat, lon, scientificname, genus, author, cityear,trt, trait, mean, n, statname, stat, notes
 	    citation_id=row[1]
 	    if (citation_id==nil)
 	      citation_id="NULL"
 	    end
 	    site_id=row[2]
 	    if (site_id==nil)
 	      site_id="NULL"
 	    end
 	    treatment_id=row[3]
 	    if (treatment_id==nil)
 	        treatment_id="NULL"
 	    end
 	    v_id="stomatal_slope"
 	    vquery="SELECT id FROM variables WHERE name='#{v_id}'"
 	    #puts "#{vquery}"
 	    vqueryresult=con.query(vquery)
 	    variable_id=0
 	    vqueryresult.each_hash do |result|
        variable_id=result['id']
      end
      scientificname=row[8]
      if scientificname!=nil
        genus=row[9]
        sidquery="SELECT id FROM species WHERE scientificname='#{scientificname}' AND genus='#{genus}'"
        #puts "#{sidquery}"
        sidqueryresult=con.query(sidquery)
        specie_id=0
        sidqueryresult.each_hash do |result|
          specie_id=result['id']
        end
      else
        species_id="NULL"
      end
      mean=row[14]
      if mean==nil
        mean="NULL"
      end
      n=row[15]
      if row==nil
        n="NULL"
      end
      statname=row[16]
      if statname==nil
        statname="NULL"
 	    end
 	    stat=row[17]
 	    if stat==nil
 	      stat="NULL"
 	    end
 	    author=row[10]
 	    #site_id,citation_id,species_id,variable_id, treatment_id,mean, n, statname, stat, 
 	    if (author!="Wolz")
 	      query="INSERT INTO traits(site_id,citation_id,specie_id,variable_id, treatment_id, mean, n, statname, stat) 
 	      VALUES (#{site_id},#{citation_id}, #{specie_id},#{variable_id}, #{treatment_id}, #{mean}, #{n}, '#{statname}',#{stat})"
 	      #puts "#{query}"
 	      con.query(query)
 	    end
 	  end
 	  linecounter+=1
 	end
 	rescue Mysql::Error => e
      puts e.errno
      puts e.error

  ensure
      con.close if con
 end
 	    
 	    