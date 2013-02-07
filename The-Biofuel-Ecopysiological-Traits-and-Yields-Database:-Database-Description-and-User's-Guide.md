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

Quick Start
===========

Open web interface:
:   [ebi-forecast.igb.uiuc.edu/bety/](http://ebi-forecast.igb.uiuc.edu/bety/)

Download data:
:   .

Enter data:
:   see the [Data Entry
    Workflow](https://netfiles.uiuc.edu/dlebauer/www/dbdocumentation_data_entry.pdf).

Read about table contents:
:   see and .

View summary of core tables and relationships : 
:   
View comprehensive schema, 
:   .

Background
==========

A major motivation of the biofuel industry is to reduce greenhouse gas
emissions by providing ecologically and economically sustainable sources
of fuel and dependence on fossil fuel. The goal of this database is to
provide a clearinghouse of existing research on potential biofuel crops,
to provide a source of data on plant ecophysiological traits and yields,
and to present ecosystem scale re-analysis and forecasts that can
support the agronomic, ecological, policy, and economic aspects of the
biofuel industry. This database will facilitate the scientific advances
and assessments that this transition will require.

Introduction
============

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

Objectives
----------

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

Scope
=====

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

Data Content
------------

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
(). These species include perennial grasses, such as Miscanthus
(*Miscanthus sinensis*) Switchgrass (*Panicum virgatum*), and sugarcane
(*Saccharyn* spp.). BETY also includes short-rotation woody species,
including poplar (*Populus* spp.) and willow (*Salix* spp.) and a group
of species that are being evaluated at the energy farm as novel woody
crops. In addition to these herbaceous species, we are collecting data
from a species in an experimental low-input, high diversity prairie.

[hbt]

  **Genus**         **Traits**   **Yields**
  ---------------- ------------ ------------
  Miscanthus           2741         506
  Populus              1740         755
  Panicum              606          1904
  Salix                146          136
  Andropogon            92      
  Agave                 88      
  Betula                70      
                                
  **PFT**                       
  forb                 287      
  tree / shrub         194           3
  sedge                 50           32
  C4 grass              43      
  C3 grass              36      
  nitrogen fixer        8       

[tab:internaldata]

Design
------

BETYdb is a relational database that comprehensively documents available
trait and yield data from diverse plant species (). The underlying
structure of BETY-db is designed to support meta-analysis and ecological
modeling. A key feature is the PFT (plant functional type) table which
allows a user to group species for analysis. On top of the database, we
have created a web-portal that targets a larger range of end users,
including scientists, agronimists, foresters, and those in the biofuel
industry.

[!hbt] ![image](summarymodel.png) [fig:summarymodel]

Data Access
-----------

[sec:download] Data is made available for analysis after it is submitted
and reviewed by a database admistrator. These data are suitable for
basic scientific research and modeling. All reviewed data are made
publicly available after publication to users of BETY-db who are
conducting primary research. Access to these raw data is provided to
users based on affiliation and contribution of data.

Data can be downloaded as a `.csv=` file, and data from previously
published syntheses can be downloaded without login. For example, to
download all of the Switchgrass (*Panicum virgatum* L.) yield data,

1.  Open the BETY homepage
    [ebi-forecast.igb.uiuc.edu](ebi-forecast.igb.uiuc.edu/bety)

2.  Select
    [**`Species database`**](http://ebi-forecast.igb.uiuc.edu/bety/maps/species_details)
    under **Search**

3.  Select
    [**`Click Here`**](http://ebi-forecast.igb.uiuc.edu/bety/maps/yields?species=938)
    under Yields

4.  to download all records as a comma-delimited (`.csv`) file, scroll
    down and select the link
    <http://ebi-forecast.igb.uiuc.edu/bety/maps/yields?format=csv\&species=938>**`CSV Format`**

Web Interface
-------------

The web interface to BETYdb provides an interactive portal in which
available data can be visualized, accessed, and entered ().

[h] ![image](betyhome.png) [fig:betyhome]

Data Entry
----------

The [Data Entry
Workflow](http://dl.dropbox.com/u/18092793/dbdocumentation_data_entry.pdf)
provides a complete description of the data entry process. BETY’s web
interface has been developed to facilitate accurate and efficient data
entry. This interface provides logical workflow to guide the user
through comprehensively documenting data along with species, site
information, and experimental methods. This workflow is outlined in the
BETYdb Data Entry. Data entry requires a login with `Create`
permissions, this can be obtained by contacting [David
LeBauer](mailto:dlebauer@illinois.edu) or [Mike
Dietze](mailto:mdietze@illinois.edu).

Tables
======

[sec:tables]

The database is designed as a relationship database management system
(RDBMS), following the normalization . Each table has a primary key
field, `id`, which is a unique identifier for each record in the table.
In addition, each record has `created_at` and `updated_at` fields. The
traits and yields tables each has a `user_id` field to record the user
who originally entered the data.

A complete list of tables is provided in , and a comprehensive
description of the contents of each table is provided below.

[!htb] [tab:tables]

llHp4in

Table &Name & Use & Description\
[tab:citations] & citations & & Citation information, links\
[tab:citations~s~ites]& citations\_sites & lookup & associates sites
with citations\
[tab:citations~t~reatments]& citations\_treatments & lookup & associates
citations with treatments\
[tab:covariates]& covariates & & covariates are required for some
traits\
[tab:cultivars]& cultivars& & cultivars associated with species\
[tab:error~l~ogs]& error\_logs & &\
[tab:managements]& managements & & quantifies managements, including
treatment levels; provides dates associated with treatments\
[tab:managements~t~reatments]& managements\_treatments & lookup &
associates managements with specific treatments\
[tab:pfts]& pfts & & defines plant functional types (PFTs), users may
choose existing pfts can be used, or user can enter pfts\
[tab:pfts~p~riors]& pfts\_priors & lookup & associates prior
parameterizations with pfts used in modeling\
[tab:pfts~s~pecies]& pfts\_species & lookup & associates species with
pfts used in modeling\
[tab:priors]& priors & & PFT level summaries of available information
for use in Bayesian meta-analysis\
[tab:sites]& sites & & Site level information\
[tab:species]& species & & Based on USDA Plants database\
[tab:traits]& traits & & Trait data table\
[tab:treatments]& treatments & & identifies experimental treatment name\
[tab:variables]& variables & & Description, including units, associated
with variables used to define traits, trait covariates, and priors\
[tab:yields]& yields & & Yield data table\

Table and field naming conventions
----------------------------------

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
use lookup tables. Lookup tables (e.g. Tables [tab:citations~s~ites],
[tab:citations~t~reatments], [tab:citations~s~ites],
[tab:managements~t~reatments], [tab:pfts~p~riors], [tab:pfts~s~pecies])
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

Data Tables
-----------

The two data tables, **traits** and **yields**, contain the primary data
of interest; all of the other tables provide information associated with
these data points. These two tables are structurally very similar as can
be seen in Tables [tab:traits] and [tab:yields].

### traits

The **traits** table contains trait data (). Traits are measurable
phenotypes that are influenced by a plants genotype and environment.
Most trait records presently in BETY describe tissue chemistry,
photosynthetic parameters, and carbon allocation by plants.

### yields

The **yields** table includes aboveground biomass in units of Mg
ha$^{-1}$ (). Biomass harvested in the fall and winter generally
represents what a farmer would harvest, whereas spring and summer
harvests are generally from small samples used to monitor the progress
of a crop over the course of the growing season. Managements associated
with Yields can be used to determine the age of a crop, the
fertilization history, harvest history, and other useful information.

Auxillary Tables
----------------

### sites

Each site is described in the **sites** table (). A site can have
multiple studies and multiple treatments. Sites are identified and
should be used as the unit of spatial replication; treatments are used
identify independent units within a site, and these can be compared to
other studies at the same site with shared management. ’’Studies’’ are
not identified explicitly but independent studies can be identified via
shared management entries at the same site.

### treatments

The **treatments** table provides a categorical identifier of a study’s
experimental treatments, if any ().

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

### managements

The **managements** table provides information on management types,
including planting time and methods, stand age, fertilization,
irrigation, herbicides, pesticides, as well as harvest method, time and
frequency.

The **managmenets** and **treatments** tables are linked through the
`managements_treatments` lookup table ([tab:managements~t~reatments]).

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

### covariates

The **covariates** table is used to record one or more covariates
associated with each trait record (). Covariates generally indicate the
environmental or experimental conditions under which a measurement was
made. The definition of specific covariates can be found in the
**variables** table (). Covariates are required for many of the traits
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

### pfts

The plant functional type (PFT) table, **pfts** is used to group plants
for statistical modeling and analysis. Each record in **pfts** contains
a PFT that is linked to a subset of species in the **species** table.
This relationship requires the lookup table **pfts\_species** ().
Furtheromre, each PFT can be associated with a set of trait prior
probability distributions in the **priors** table (). This relationship
requires the lookup table **pfts\_priors** ().

In many cases, it is appropriate to use a pre-defined default PFT (e.g.
`tempdecid` is temperate deciduous trees) In other cases, a user can
define a new pft to query a specific set of priors or subset of species.
For example, there is a PFT for each of the functional types found at
the EBI Farm prairie. Such project-specific PFTs can be defined as
`` `projectname`.`pft` `` (i.e. `ebifarm.c4grass` instead of `c4grass`).

### variables

The **variables** table includes definitions of different variables used
in the traits, covariates, and priors tables (). Each variable has a
`name` field, and is associated with a standardized value for `units`.
The `description` field provides additional information or context about
the variable.

Lookup Tables
-------------

Lookup tables are required when each record on one table can be related
to many records on another table, and vice-versa; this is called a ’many
to many’ relationship.

### citations\_sites

Because a single study can use multiple sites and multiple studies can
use the same site, these relationships are tracked in the
**citation\_sites** table ().

### citations\_treatments

Because a single study can include multiple treatments and each
treatment can be associated with multiple citations, these relationships
are measured in **citations\_treatments** table ().

### managements\_treatments

It is clear that one treatment can have many managements, e.g. tillage,
planting, fertilization. It is also important to note that any
managements applied to a control plot should, by definition, be
associated with all of the treatments in an experiment; this is why the
many-to-many lookup table **managements\_treatments** is required.

### pfts\_priors

The **pfts\_priors** table allows a many to many relationship between
the **pfts** and **priors** tables (). This allows each pft to be
associated with multiple priors and each prior to be associated with
multiple pfts.

### pfts\_species

The **pfts\_species** table allows a many to many relationship between
the **pfts** and **species** tables ().

Acknowlegments
==============

BETY-db is a product of the Energy Biosciences Institute at the
University of Illinois at Urbana-Champaign. Funding for this research
was provided by British Petroleum through a grant to the Energy
Biosciences institute. We gratefully acknowledge the great effort of
other researchers who generously made their own data available for
further study.

Appendix
========

Full Schema: Enhanced Entity-Relationship Model
-----------------------------------------------

provides a visualization of the complete schema, including
interrelationships among tables, of the biofuel database.

[hbtp] ![image](model.pdf) [fig:model]

Software
--------

The BETY-db has beeen developed in MySQL using Ruby on Rails and is
hosted on a RedHat Linux Server (ebi-forecast.igb.uiuc.edu). BETY-db is
a relational database designed in a generic way to facilitate easy
implementation of additional traits and parameters.

