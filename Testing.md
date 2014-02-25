# Running the RSpec tests on betydb.

## Preparing the test database.

1. Go to the root directory of the copy of the bety rails app you are testing.
1. To ensure you have configured the test database in rails, run `less config/database.yml` and see that there is a section headed `test:`.
1. Ensure the database listed as the test database exists.  If you need to create it, in PostgreSQL, you can use the `createdb` command.  For example, if the test block of database.yml lists "bety" as the username and "test" as the database, use the command `createdb -O bety test` to create a database named "test" owned by user "bety".  (Or use `sudo -u postgres createdb -O bety bety` if you yourself don't have the needed permissions to create new databases.)  In MySQL, start the mysql client as user "bety" and run the command `CREATE DATABASE test;`.
1. `rake db:test:clone` will clone the current environment's database schema into the test database, purging any data and schema that were already there so that you can start fresh. (The tables will all be empty.)  This step assumes the current environment (which is most likely "development") has its database already set up with the correct database schema.  [NOTE: I found that I ran into permissions problems when attempting this step.  To get around this, I started psql as a superuser and then ran "ALTER USER bety WITH SUPERUSER;" to make user bety a superuser as well.  This shouldn't be a security worry if you are just running tests on your own copy of BetyDB, although probably lesser permissions could be granted which would fix the problem.  You may have to re-create the test database (previous step) after a failed clone attempt.]
1. `rake db:fixtures:load RAILS_ENV=test` will load the data in the fixtures.  These are YAML files under `test/fixtures`.


## Running the tests

* The simplest way to run the tests is to simply run `rspec` from the root directory of the copy of the bety rails app you are testing. This will run all the tests under the "spec" directory.
* To run a specific file of tests, run `rspec path/to/testfile`.
* You can run a specific test in a file by appending a line number: `rspec path/to/testfile:line_number_of_first_line_of_test`.  This command will appear under the "Failed examples" section of a test run (assuming the test failed); for example `rspec ./spec/features/management_integration_spec.rb:48`
* Some useful options to rspec are: 
  1. --fail-fast (Abort the run on first failure)
  2. --format doc (get nicely formatted output)