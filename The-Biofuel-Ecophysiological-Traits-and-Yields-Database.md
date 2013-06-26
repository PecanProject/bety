# The Biofuel Ecophysiological Traits and Yields Database: 
# Database Description and User's Guide 
## Version 1.0

## David LeBauer, Dan Wang, Patrick Mulrooney, Mike Dietze

*Please cite this document regarding the implementation and structure of
BETY:*

   David LeBauer, Dan Wang, Patrick Mulrooney, Mike Dietze. 2011. The
Biofuel Ecopysiological Traits and Yields Database: Database Description
and User’s Guide, Version 1.0

*Please cite the use of data contained in BETY:*

   David LeBauer, Dan Wang, and Michael Dietze, 2010. Biofuel
Ecophysiological Traits and Yields Database Version 1.0. Energy
Biosciences Institute, Urbana, IL.
`http://ebi-forecast.igb.uiuc.edu/bety`

## 1. Quick Start

Open web interface:   [ebi-forecast.igb.uiuc.edu/bety/](http://ebi-forecast.igb.uiuc.edu/bety/)

Download data: [Section 4.3] (#Section 4.3)

Enter data: see the [Data Entry Workflow](https://netfiles.uiuc.edu/dlebauer/www/dbdocumentation_data_entry.pdf).

Read about table contents: see [Table 2] (#Table 2) and [Section 5] (#Section 5).

View summary of core tables and relationships : [Figure 1] (#Figure 1)

View comprehensive schema: [Figure 3] (#Figure 3)

## 2. Background

A major motivation of the biofuel industry is to reduce greenhouse gas
emissions by providing ecologically and economically sustainable sources
of fuel and dependence on fossil fuel. The goal of this database is to
provide a clearinghouse of existing research on potential biofuel crops,
to provide a source of data on plant ecophysiological traits and yields,
and to present ecosystem scale re-analysis and forecasts that can
support the agronomic, ecological, policy, and economic aspects of the
biofuel industry. This database will facilitate the scientific advances
and assessments that this transition will require.

## 3. Introduction


This document describes the purpose, design, and use of the Biofuel
Ecophysiological Traits and Yields database (BETYdb). BETYdb is a
database of plant trait and yield data that supports research,
forecasting, and decision making associated with the development and
production of cellulosic biofuel crops. While the content of BETYdb is
agronomic, the structure of the database itself is general and can
therefore be used more generally for ecosystem studies.

BETY-db can be accessed online at
[ebi-forecast.igb.uiuc.edu/bety/](http://ebi-forecast.igb.uiuc.edu/bety/).
For developers interested in the database description in SQL syntax,
e.g. to explore, create, and modify its structure, the
[betydb\_schema](https://github.com/dlebauer/BETYdb/raw/master/betydb_schema.sql)
is available. or further information about the procedures that are used
to enter data into the database, see the accompanying [Data Entry
Workflow](https://netfiles.uiuc.edu/dlebauer/www/dbdocumentation_data_entry.pdf).

### 3.1 Objectives


The objectives of this database are to allow other users access data
that has been collected from previously published and ongoing research
in a consistent format, and to provide a streamlined interface that
allows users to enter their own data. These objectives will support
specific research and collaboration, advance agricultural practices, and
inform policy decisions. Specifically, BETYdb supports the following
uses:

1.  Carry out statistical analyses to explore the relationships between
    traits

2.  Identify differences among species and functional groups

3.  Access BETY-db from simulation models to look up values for traits
    and parameter

4.  Identify gaps in knowledge about biofuel crop traits and model
    parameters to aid rational planning of research activities

BETYdb provides a central clearinghouse of biofuel crop physiological
traits and yields in a consistently organized framework that simplifies
the use of these data for further analysis and interpretation.
Scientific applications include the development, assessment, and
prediction of crop yields and ecosystem services in biofuel
agroecosystems. The database directly supports parameterization and
validation of ecological, agronomic, engineering, and economic models.
The initial target end-users of BETY-db version 1.0 are users within EBI
who aim to support sustainable biofuel production through statistical
analysis and ecological modeling. By streamlining the process of data
summary, we hope to inspire new scientific perspectives on biofuel crop
ecology that are based on a comprehensive evaluation of available
knowledge.

Published data and analyses will be provided to other scientists and the
public in an easy to understand, interactive web front end to the
database.

## 4. Scope


The database contains trait, yield, and ecosystem service data. Because
all plants have the potential to be used as biofuel feedstock, BETYdb
supports data from all plant species. In practice, the species included
in the database reflect available data and the past and present research
interests of contributors. Trait and yield data are provided at the
level of species, with cultivar and clone information provided where
available.

The yield data not only includes end of season harvestable yield, but
also includes measurements made over the course of the growing season.
These yield data are useful in the assessment of historically observed
crop yields, and they can also be used in the validation of plant
models. Yield data includes peak biomass, harvestable biomass, and the
biomass of the crop throughout the growing season.

The trait data represent phenotypic traits; these are measurable
characteristics of an organism. The primary objective of the trait data
is to allow researchers to model second generation biofuel crops such as
Miscanthus and Switchgrass. In addition, these data enable evaluation of
new plant species as potenial biofuel crops. Ecosystem service data
reflect ecosystem-level observations, and these data are included in the
traits table.

### 4.1 Data Content


BETYdb includes data obtained through extensive literature review of
target species in addition to data collected from the Energy Farm at the
University of Illinois, and by our collaborators. The BETYdb database
contains trait and yield data for a wide range of plant species so that
it is possible to estimate the distribution of plant traits for broad
phylogenetic groups and plant functional types.

BETYdb contains data from intensive efforts to find data for specific
species of interest as well as from previous plant trait and yield
syntheses, and other databases. Most of the data currently in the
database is from plant groups that are the focus of our current research
[Table 1](#Table 1). These species include perennial grasses, such as Miscanthus
(*Miscanthus sinensis*) Switchgrass (*Panicum virgatum*), and sugarcane
(*Saccharyn* spp.). BETY also includes short-rotation woody species,
including poplar (*Populus* spp.) and willow (*Salix* spp.) and a group
of species that are being evaluated at the energy farm as novel woody
crops. In addition to these herbaceous species, we are collecting data
from a species in an experimental low-input, high diversity prairie.


<a id="Table 1"></a>
**Table 1**: Data from the targeeted species-specific data collection for BETYdb. Data are summarized by genus fo rthe top seven genera, and the rest of the data are summarzied by plant function type.   
![Alt text] (figures/ug table 1.png "Table 1")   

<a id="Figure 1"></a>  
![Alt text] (figures/ug figure 1.png "Figure 1")  
**Figure 1**: Abbreviated schema for BETYdb 

### 4.2 Design


BETYdb is a relational database that comprehensively documents available
trait and yield data from diverse plant species [Figure 1](#Figure 1). The underlying
structure of BETY-db is designed to support meta-analysis and ecological
modeling. A key feature is the PFT (plant functional type) table which
allows a user to group species for analysis. On top of the database, we
have created a web-portal that targets a larger range of end users,
including scientists, agronimists, foresters, and those in the biofuel
industry.

### Web Interface

The web interface to BETYdb provides an interactive portal in which
available data can be visualized, accessed, and entered [Figure 2](#Figure 2).

<a id="Figure 2"></a>  
![Alt text] (figures/ug figure 2.png "Figure 2")   
**Figure 2**: The BETYdb web interface homepage

### Data Entry


The [Data Entry
Workflow | Data-Entry-Workflow-for-the-Biofuel-Ecophysiological-Traits-and-Yields-Database-(BETYdb] provides a complete description of the data entry process. BETY’s web
interface has been developed to facilitate accurate and efficient data
entry. This interface provides logical workflow to guide the user
through comprehensively documenting data along with species, site
information, and experimental methods. This workflow is outlined in the
BETYdb Data Entry. Data entry requires a login with `Create`
permissions, this can be obtained by contacting [David
LeBauer](mailto:dlebauer@illinois.edu) or [Mike
Dietze](mailto:mdietze@illinois.edu).

<a id="Section 5"></a> 
## 5. Tables


The database is designed as a relationship database management system
(RDBMS), following the normalization [Figure 1] (#Figure 1). Each table has a primary key
field, `id`, which is a unique identifier for each record in the table.
In addition, each record has `created_at` and `updated_at` fields. The
traits and yields tables each has a `user_id` field to record the user
who originally entered the data.

A complete list of tables is provided in [Table 2](#Table 2), and a comprehensive
description of the contents of each table is provided below.

<a id="Table 2"></a>  
![Alt text] (figures/ug table 2.png "Table 2") 


### 5.1 Table and field naming conventions


Each table is given a name that describes the information that it
contains. For example, the table containing trait data is called
`traits`, the table containing yield data is `yields`, and so on. Each
table also has a *primary key*; the primary key is always `id`, and the
primary key of a specific table might be identified as `yields.id` . One
table can reference another table using a *foreign key*; the foreign key
is given a name using the singular form of the foreign table, and
underscore, and id, e.g. `traits_id` or `yields_id`.

In some cases, two tables can have multiple references to one another,
known as a ’many to many’ or ’m:n’ relationship. For example, one
citation may contain data from many sites; at the same time, data from a
single site may be included in multiple citations. Such relationships
use lookup tables. Lookup tables (e.g. [Table 4](#Table 4), [Table 5](#Table 5), [Table 10](#Table 10), [Table 12](#Table 12), [Table 13](#Table 13))
combine the names of the two tables being related, in the case of this
example, the table used to link `citations` and `sites` is named
`citations_sites`. These lookup tables have two foreign keys, e.g.
`citation_id` and `site_id` but do not have a primary key The foreign
keys are identified by `FK: table.column` in the comment fields of the
database tables where `table` is either a) for 1:many relationships the
name of the master table in which `column` is the primary key or b) for
many to many (m:n) relationships, to the auxillary table with `column`
adjacent to another column with which the m:n relationship is simplified
into 1:m and 1:n relationships.

### 5.2 Data Tables

The two data tables, **traits** and **yields**, contain the primary data
of interest; all of the other tables provide information associated with
these data points. These two tables are structurally very similar as can
be seen in [Table 17](#Table 17) and [Table 20](#Table 20).

#### traits

The **traits** table contains trait data ([Table 17](#Table 17)). Traits are measurable
phenotypes that are influenced by a plants genotype and environment.
Most trait records presently in BETY describe tissue chemistry,
photosynthetic parameters, and carbon allocation by plants.

#### yields

The **yields** table includes aboveground biomass in units of Mg
ha$^{-1}$ ([Table 20](#Table 20)). Biomass harvested in the fall and winter generally
represents what a farmer would harvest, whereas spring and summer
harvests are generally from small samples used to monitor the progress
of a crop over the course of the growing season. Managements associated
with Yields can be used to determine the age of a crop, the
fertilization history, harvest history, and other useful information.

### 5.3 Auxillary Tables


#### sites

Each site is described in the **sites** table ([Table 15](#Table 15)). A site can have
multiple studies and multiple treatments. Sites are identified and
should be used as the unit of spatial replication; treatments are used
identify independent units within a site, and these can be compared to
other studies at the same site with shared management. ’’Studies’’ are
not identified explicitly but independent studies can be identified via
shared management entries at the same site.

#### treatments

The **treatments** table provides a categorical identifier of a study’s
experimental treatments, if any ([Table 18](#Table 18)).

Any specific information such as rate of fertilizer application should
be recorded in the managements table (section. A treatment name is used
as a categorical (rather than continuous) variable, and the name relates
directly to the nomenclature used in the original citation. The
treatment name does not have to indicate the level of treatment used in
a particular treatment - if required for analysis, this information is
recorded as a management.

Each study includes a control treatment, when there is no experimental
manipulation, the treatment is considered ’observational’ and listed as
control. In studies that compare plant traits or yields across different
genotypes, site locations, or other factors that are built in to the
database, each record is associated with a separate cultivar or site so
these are not considered treatments.

For ambiguous cases, the control treatment is assigned to the treatment
that best approximates the background condition of the system in its
non-experimental state, for this reason, a treatment that approximates
conventional agronomic practice may be labeled ’control’.

#### managements

The **managements** table provides information on management types,
including planting time and methods, stand age, fertilization,
irrigation, herbicides, pesticides, as well as harvest method, time and
frequency.

The **managmenets** and **treatments** tables are linked through the
`managements_treatments` lookup ([Table 10](#Table 10)).

Managements are distinct from treatments in that a management is used to
describe the agronomic or experimental intervention that occurs at a
specific time and may have a quantity whereas Treatment is a categorical
identifier of an experimental group. Managements include actions that
are done to a plant or ecosystem, for example the planting density or
rate of fertilizer application.

In other words, managements are the way a treatment becomes quantified.
Each treatment can be associated with multiple managements. The
combination of managements associated with a particular treatment will
distinguish it from other treatments. Each management may be associated
with one or more treatments. For example, in a fertilization experiment,
planting, irrigation, and herbicide managements would be applied to all
plots but the fertilization will be specific to a treatment. For a
multi-year experiment, there may be multiple entries for the same type
of management, reflecting, for example, repeated applications of
herbicide or fertilizer.

#### covariates

The **covariates** table is used to record one or more covariates
associated with each trait record ([Table 6](#Table 6)). Covariates generally indicate the
environmental or experimental conditions under which a measurement was
made. The definition of specific covariates can be found in the
**variables** table ([Table 19](#Table 19)). Covariates are required for many of the traits
because without covariate information, the trait data will have limited
value.

The most frequently used covariates are the temperature at which some
respiration rate or photosynthetic parameter was measured. For example,
photosynthesis measurements are often recorded along with irradiance,
temperature, and relative humidity.

Other covariates include the size or age of the plant or plant part
being measured. For example, root respiration is usually measured on
fine roots, and if the authors define fine root as \<2mm, the covariate
root\_minimum\_diameter has a value of $2$.

#### pfts

The plant functional type (PFT) table, **pfts** is used to group plants
for statistical modeling and analysis. Each record in **pfts** contains
a PFT that is linked to a subset of species in the **species** table.
This relationship requires the lookup table **pfts\_species** ([Table 13](#Table 13)).
Furtheromre, each PFT can be associated with a set of trait prior
probability distributions in the **priors** table ([Table 14](#Table 14)). This relationship
requires the lookup table **pfts\_priors** ([Table 12](#Table 12)).

In many cases, it is appropriate to use a pre-defined default PFT (e.g.
`tempdecid` is temperate deciduous trees) In other cases, a user can
define a new pft to query a specific set of priors or subset of species.
For example, there is a PFT for each of the functional types found at
the EBI Farm prairie. Such project-specific PFTs can be defined as
`` `projectname`.`pft` `` (i.e. `ebifarm.c4grass` instead of `c4grass`).

#### variables

The **variables** table includes definitions of different variables used
in the traits, covariates, and priors tables ([Table 19](#Table 19)). Each variable has a
`name` field, and is associated with a standardized value for `units`.
The `description` field provides additional information or context about
the variable.

### 5.4 Lookup Tables


Lookup tables are required when each record on one table can be related
to many records on another table, and vice-versa; this is called a ’many
to many’ relationship.

#### citations\_sites

Because a single study can use multiple sites and multiple studies can
use the same site, these relationships are tracked in the
**citation\_sites** table ([Table 4](#Table 4)).

#### citations\_treatments

Because a single study can include multiple treatments and each
treatment can be associated with multiple citations, these relationships
are measured in **citations\_treatments** table ([Table 5](#Table 5)).

#### managements\_treatments

It is clear that one treatment can have many managements, e.g. tillage,
planting, fertilization. It is also important to note that any
managements applied to a control plot should, by definition, be
associated with all of the treatments in an experiment; this is why the
many-to-many lookup table **managements\_treatments** is required.

#### pfts\_priors

The **pfts\_priors** table allows a many to many relationship between
the **pfts** and **priors** tables ([Table 12](#Table 12)). This allows each pft to be
associated with multiple priors and each prior to be associated with
multiple pfts.

#### pfts\_species

The **pfts\_species** table allows a many to many relationship between
the **pfts** and **species** tables ([Table 12](#Table 12)).

## Documentation

Reference: [dba.SE question](http://dba.stackexchange.com/a/24557/1580)

Related Issue: [#2 script that provides on-demand updated documentation](https://github.com/PecanProject/bety/issues/2)

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



## 6. Acknowlegments


BETY-db is a product of the Energy Biosciences Institute at the
University of Illinois at Urbana-Champaign. Funding for this research
was provided by British Petroleum through a grant to the Energy
Biosciences institute. We gratefully acknowledge the great effort of
other researchers who generously made their own data available for
further study.

## 7. Appendix


### 7.1 Full Schema: Enhanced Entity-Relationship Model

[Figure 3](#Figure 3) provides a visualization of the complete schema, including
interrelationships among tables, of the biofuel database.

<a id="Figure 3"></a>  
![Alt text] (figures/ug figure 3.png "figure 3")   
**Figure 3**: Full schema of BETYdb, showing all tables and relations on the data base


[Figure 3.1](#Figure 3.1) provides a visualization of the complete schema, including
interrelationships among tables, of the biofuel database.

<a id="Figure 3.1" style="width: 600 height: 400"></a>  
![Alt text] (figures/models_brief_small.png "figure 3.1")   
**Figure 3**: View of Database from perspective of Ruby

### 7.2 Software


The BETY-db has beeen developed in MySQL using Ruby on Rails and is
hosted on a RedHat Linux Server (ebi-forecast.igb.uiuc.edu). BETY-db is
a relational database designed in a generic way to facilitate easy
implementation of additional traits and parameters.

## 8 Software 
<a id="Table 3"></a>  
![Alt text] (figures/ug table 3.png "Table 3")   

<a id="Table 4"></a>  
![Alt text] (figures/ug table 4.png "Table 4")   

<a id="Table 5"></a>  
![Alt text] (figures/ug table 5.png "Table 5")   

<a id="Table 6"></a>  
![Alt text] (figures/ug table 6.png "Table 6")   

<a id="Table 7"></a>  
![Alt text] (figures/ug table 7.png "Table 7")   

<a id="Table 8"></a>  
![Alt text] (figures/ug table 8.png "Table 8")   

<a id="Table 9"></a>  
![Alt text] (figures/ug table 9.png "Table 9")     

<a id="Table 10"></a>  
![Alt text] (figures/ug table 10.png "Table 10")   

<a id="Table 11"></a>  
![Alt text] (figures/ug table 11.png "Table 11")     

<a id="Table 12"></a>  
![Alt text] (figures/ug table 12.png "Table 12")   

<a id="Table 13"></a>  
![Alt text] (figures/ug table 13.png "Table 13")   

<a id="Table 14"></a>  
![Alt text] (figures/ug table 14.png "Table 14")   

<a id="Table 15"></a>  
![Alt text] (figures/ug table 15.png "Table 15")   

<a id="Table 16"></a>  
![Alt text] (figures/ug table 16.png "Table 16")   

<a id="Table 17"></a>  
![Alt text] (figures/ug table 17.png "Table 17")   

<a id="Table 18"></a>  
![Alt text] (figures/ug table 18.png "Table 18")   

<a id="Table 19"></a>  
![Alt text] (figures/ug table 19.png "Table 19")   

<a id="Table 20"></a>  
![Alt text] (figures/ug table 20.png "Table 20")   