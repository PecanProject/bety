require 'csv'
require 'mysql'
require 'time'
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
	nosites=Array.new
	nositescounter=0;
	CSV.foreach('sugarcaneyields.csv') do |row|
	  if (linecounter!=0)
	    #yields table fields id citation_id site_id(query and get the proper id for these fields)
  	  yid=row[0]
  	  if (yid==nil)
  	    yid=nil
  	  end
  	  citation_id=row[1]
  	  if (citation_id==nil)
  	    citation_id=0
  	  end
  	  sid=row[2]
  	  if (sid!=nil)
  	    siteidquery="SELECT id FROM temp WHERE name='#{sid}'"
  	    sidqresult=con.query(siteidquery)
  	    site_id=0;
  	    sidqresult.each_hash do |result|
  	      site_id=result['id']
  	    end
      else
        site_id=0
      end
      specie_id=row[3]
      if (specie_id==nil)
        specie_id=nil
      end
      treatment_id=row[4]
      if (treatment_id==nil)
        treatment_id=nil
      end
      cid=row[5] # fix by making a temp table for cultivars and do the same thing as you did with sites
      if (cid!=nil)
        cultivaridquery="SELECT id FROM tempcultivar WHERE name='#{cid}'"
        cultidresult=con.query(cultivaridquery)
        cultivar_id=0;
        cultidresult.each_hash do |result|
          cultivar_id=result['id']
        end
      else
        cultivar_id=0
      end
      date=row[6]
      if (date==nil)
        date=nil
      elsif(date=='08/01/2001')
        date='08/01/2001'
      end
      dateloc=row[7]
      if (dateloc==nil)
        dateloc=nil
      end
      statname=row[8]
      if (statname==nil)
        statname=nil
      end
      stat=row[9]
      if (stat==nil)
        stat=0;
      end
      mean=row[10]
      if (mean==nil)
        mean=nil
      end
      n=row[11]
      if (n==nil)
        n=0
      end
      notes=row[12]
      if (notes==nil)
        notes=nil;
      end
      created_at=row[13]
      if (created_at==nil)
        created_at="NULL"
      end
      updated_at=row[14]
      if (updated_at==nil)
        updated_at="NULL";
      end
      user_id=row[15]
      if (user_id==nil)
        user_id=0;
      end
      checked=row[16]
      if (checked==nil)
        checked=0;
      end
      access_level=row[17]
      if (access_level==nil)
        access_level=0;
      end
      if (site_id==0)
        nosites[nositescounter]=linecounter;
        nositescounter=nositescounter+1
      end
      if (specie_id==nil)
        puts "finished\n"
        break
      end
      if (date=='8/1/01')
        date='08/01/2001'
      end
      query="INSERT INTO yields(citation_id, site_id, specie_id, treatment_id, cultivar_id, date, dateloc
      , statname, stat, mean, n, notes, created_at, updated_at, user_id, checked, access_level) 
      VALUES(#{citation_id}, '#{site_id}', '#{specie_id}', '#{treatment_id}', '#{cultivar_id}', #{date}, '#{dateloc}', '#{statname}', '#{stat}', #{mean}, '#{n}', '#{notes}', #{created_at},
      #{updated_at}, #{user_id}, '#{checked}', #{access_level})"
      puts "#{query}\n"
      puts "linecounter=#{linecounter} citation_id=#{citation_id} site_id=#{site_id} specie_id=#{specie_id} treatment_id=#{treatment_id}\n"
      puts "cultivar_id=#{cultivar_id} date=#{date} dateloc= #{dateloc} statname= #{statname} stat=#{stat} mean=#{mean}\n"
      puts "n=#{n} notes=#{notes} created_at=#{created_at} updated_at=#{updated_at} user_id=#{user_id} checked =#{checked}\n"
      puts "access_level=#{access_level}\n"
      date=nil;
      con.query(query)
    end
    linecounter=linecounter+1;
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
    
    