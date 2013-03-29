# This is a Draft

## Documenting Tables and Columns in MySQL

Reference: [dba.SE question](http://dba.stackexchange.com/a/24557/1580)

Related Issue: #2

### Adding Comments to Tables and Columns

#### Add comment to table

```sql
alter table [TABLE NAME] comment '[COMMENT]';
```
#### Add comment to column

##### syntax:

```sql
alter table [TABLE NAME] change column [COLUMN NAME] [COLUMN NAME] [TYPE] comment "[COMMENT]";
```

##### example: Add comment to column “specie_id” field in yields

```sql
alter table yields change column specie_id specie_id int(11) comment "lookup table for species ";
```

* Important:
  * the repetition of the column name is required
  *  the column “type” is also required. of the `notes notes text` is required, both the repetition of the column name and the statement of the column type ( in this case text).

### Export documentation tables above from the INFORMATION_SCHEMA database in MySQL:

#### Tables

```sql
use INFORMATION_SCHEMA
select distinct TABLE_NAME, TABLE_COMMENT from TABLES 
    where TABLE_SCHEMA = "ebi_production" and TABLE_COMMENT is not "VIEW";
```

#### Columns

Example for the yields table:

```sql
select column_name, column_comment from INFORMATION_SCHEMA.COLUMNS 
    where TABLE_NAME = "yields" and TABLE_SCHEMA = "ebi_analysis";
```


## Introduction to Ruby-on-Rails

### Commenting in the Rails Models


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