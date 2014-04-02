# Ruby-on-Rails

## Deploying a new version:

1. test on `pecandev.igb.illinois.edu:/usr/local/ebi`
2. test on `ebi-forecast.igb.illinois.edu:/usr/local/beta`
3. deploy on `ebi-forecast.igb.illinois.edu:/usr/local/ebi`

```{bash}
cd /usr/local/ebi
git status
git pull
touch tmp/restart.txt
```

## Commenting in the Rails Models


Example of a properly commented citation model (
/app/models/citations.rb ):
[https://gist.github.com/e68fea1baa070e68b984](https://gist.github.com/e68fea1baa070e68b984)

And a properly commented covariates model ( /app/models/covariates.rb
):
[https://gist.github.com/5d0d96d7be1b1fd7b47c](https://gist.github.com/5d0d96d7be1b1fd7b47c)

## Introduction to MVC

## Source Code Map

## Misc. Information

### Providing model output for download

Access to download model output is in app/views/maps/locations_yields.html.erb

### Related Issues / Commits: 

https://github.com/PecanProject/bety/commit/7b7d56fdf4c577fa14d65fcf81c677f5a4bf0633

## Testing

As of commit 92ec3eed Our application has a quick and easy way to setup a test environment.

1. Create a test database, and have the login credentials for that database in /config/database.yml
```
$ mysql -u root -p
> create database bety_test;
> grant all privileges on bety to bety_user@localhost;
> exit;
```
2. Config the connection to the bety_test in RAILS_DIR/config/database.yml
```
test:
  adapter: mysql2
  encoding: latin1 
  reconnect: false
  database: ebi_test
  pool: 5
  username: bety_user
  password: somepassword
```
2. Build up the test database from the current schema:
```
$ rake db:test:load
```
3. Load the fixtures ( essentially dummy-data used for testing )
```
$ rake db:fixtures:load RAILS_ENV=test
```
4. Run the tests
```
$ rspec spec/
```
... OR ...
5. Run a specific individual test
```
$ rspec spec/features/user_integration_spec.rb
```
6. Expect to see some kind of output like this:
```
Finished in 13.73 seconds
29 examples, 0 failures
```