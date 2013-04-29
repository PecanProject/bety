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
  con = Mysql.new("#{host}","#{username}","#{password}","#{database}")# I can't get the linking to work for somereason with variables
  linecounter=0;
	#mtempquery= "CREATE TABLE temp(name VARCHAR(25), id INT(11))"
	#con.query(mtempquery)     creating a temporary table to store the ids. 
	CSV.foreach('sugarcanesites.csv') do |row| 
		  if linecounter!=0 #row 1 is the list of column heads
		    id=row[0]; 
		    if (id==nil)
		      id=nil
		    end
  		  usgsmuid=row[1] #not in database fields
  		  if (usgsmuid==nil)
		      usgsmuid=nil
		    end
  		  city=row[2]
  		  if (city==nil)
		      city=nil
		    end
  		  state=row[3]
  		  if (state==nil)
		      state=nil
		    end
  		  country=row[4]
  		  if (country==nil)
		      country=nil
		    end
  		  lat=row[5]
  		  if (lat==nil)
		      lat=nil
		    end
  		  lon=row[6]
  		  if (lon==nil)
		      lon=nil
		    end
  		  gdd=row[7] #not in database fields
  		  if (gdd==nil)
		      gdd=nil
		    end
  		  firstkillingfrost=row[8]
  		  if (firstkillingfrost==nil)
		      firstkillingfrost=nil
		    end
  		  mat=row[9]
  		  if (mat==nil)
  		    mat=0 # numerical check default null
  		  end
  		  map=row[10]
  		  if (map==nil)
		      map=0 #numerical check default null
		    end
  		  masl=row[11]
  		  if (masl==nil)
		      masl="NULL"
		    end
  		  soil=row[12]
  		  if (soil==nil)
		      soil="NULL"
		    end
  		  zrt=row[13] #not in database fields
  		    if (zrt==nil)
  		      zrt=nil
  		    end
  		  zh2o=row[14]
  		    if (zh2o==nil)
  		      zh2o=nil
  		    end
  		  som=row[15]
  		    if (som==nil)
  		      som=0 # numerical check default null
  		    end
  		  notes=row[16]
  		    if (notes==nil)
  		      notes="NULL"
  		    end
  		  soilnotes=row[17]
  		  if (soilnotes==nil)
  		    soilnotes="NULL"
  		  end
  		  created_at=row[18]
  		    if (created_at==nil)
  		      created_at="NULL"#date format check default
  		    end
  		  updated_at=row[19]
  		  if (updated_at==nil)
  		    updated_at="NULL" #date format check default
  		  end
  		  sitename=row[20]
  		    if (sitename==nil)
  		      sitename=nil
  		    end
  		  greenhouse=row[21]
  		    if (greenhouse==nil)
  		      greenhouse=0
  		    end
  		#fields of interest for database entering
  		#city  state country  lat  lon   mat   map   masi   soil 
  		#som  notes  soilnotes  created_at 
  		#updated_at  sitename   greenhouse   user_id   
  		#local_time  sand_pct   clay_pct     espg
      
      query="INSERT INTO sites(city, state, country, lat, lon, mat, map, masl, soil, som, notes, soilnotes,
      created_at, updated_at, sitename, greenhouse)
      VALUES ('#{city}', '#{state}', '#{country}', '#{lat}', '#{lon}'
      , '#{mat}', '#{map}', #{masl}, '#{soil}',#{som}, #{notes}, #{soilnotes}, #{created_at}, #{updated_at}, 
      '#{sitename}', '#{greenhouse}')"
      puts "linecounter=#{linecounter}  city = #{city} state= #{state} country= #{country} lat=#{lat}\n"
      puts "lon= #{lon} mat = #{mat} map = #{map} masl= #{masl} \nsoil=#{soil}\n"
      puts "som=#{som} notes=#{notes} soilnotes= #{soilnotes}\n"
      puts "created_at =#{created_at} updated_at=#{updated_at} sitename=#{sitename} greenhouse=#{greenhouse}"
      con.query(query);
      idquery="SELECT id FROM sites where lon=#{lon} AND lat=#{lat} AND sitename='#{sitename}' AND state='#{state}'"
      idresult=con.query(idquery);
      number=0;
      idresult.each_hash do |site|
        number=site['id']
      end
        
      tempquery="INSERT INTO temp(name,id) VALUES('#{id}',#{number})"   # add stuff to temporary database.
      con.query(tempquery)
    end
    linecounter=linecounter+1;
  end

  rescue Mysql::Error => e
      puts e.errno
      puts e.error

  ensure
      con.close if con
end
			