
require 'mysql'

begin 
  con = Mysql.new 'localhost','root','password' ##make a new mysql connection using root as your user password as password
  rs= con.query 'INSERT INTO yields(id,site_id,citation_id,cultivar_id,treatment_id) Values( %{id} , %{site_id} , %{citation_id} ,  %{cultivar_id}, %{treatment_id})'
  # an example query on how to put things in the db.
  
rescue Mysql::Error => e
    puts e.errno
    puts.e.error
    
ensure
    con.close if con
end