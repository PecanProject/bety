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
	#maketbquery= con.query 'CREATE TABLE tempcultivar(name VARCHAR(25),id INT(11))'
	CSV.foreach('sugarcanecultivars.csv') do |row| 
		  if linecounter!=0 #row 1 is the list of column heads
		    id = row[0];
		    if (id==nil)
		      id="NULL"
		    end
		    species_id=row[1];
		    if (species_id==nil)
		      species_id="NULL"
		    end
		    name=row[2];
		    if (name==nil)
		      name="NULL"
	      else
	        name=name.tr('-','')
	      end
		    ecotype=row[3]
		    if (ecotype==nil)
		      ecotype="NULL"
		    end
		    notes=row[4]
		    if (notes==nil)
		      notes="NULL"
		    end
		    created_at=row[5]
		    if (created_at==nil)
		      created_at="NULL"
		    end
		    updated_at=row[6]
		    if (updated_at==nil)
		      updated_at="NULL"
		    end
		    previous_id=row[7]
		    if (previous_id==nil)
		      previous_id="NULL"
		    end
		    query = "INSERT INTO cultivars(specie_id, name, ecotype, notes, created_at, updated_at, previous_id)
		    VALUES(#{species_id}, '#{name}' , #{ecotype}, #{notes}, #{created_at}, #{updated_at}, #{previous_id})"
		  
		    puts "id=#{id} specie_id= #{species_id} name= #{name} ecotype=#{ecotype}\n"
		    puts "notes=#{notes} created_at= #{created_at} updated_at= #{updated_at} previous_id=#{previous_id}\n"
		    con.query(query)
		    idquery="SELECT id FROM cultivars WHERE specie_id='#{species_id}' AND name='#{name}'"
		    idresult=con.query(idquery);
        number=0;
        idresult.each_hash do |site|
          number=site['id']
        end 
        puts "number=#{number} name=#{name}\n"
		    tempcultquery="INSERT INTO tempcultivar(name,id) VALUES('#{name}', '#{number}')"
		    con.query(tempcultquery)
		    #add temp query and get id;
		  end
		linecounter=linecounter+1
  end
  rescue Mysql::Error => e
      puts e.errno
      puts e.error

  ensure
      con.close if con
end
