Welcome to the bety wiki!
# Using BETYdb

**_Under Construction_**

Please see documentation here: https://www.betydb.org/dbdocumentation_users.pdf

# Data Entry
## Getting Started

You will need to create the following accounts:
* Redmine https://ebi-forecast.igb.illinois.edu/redmine/account/register
* BETYdb https://www.betydb.org/signup
* GitHub https://github.com/
* Mendeley www.mendeley.com/

Then please read the [Data Entry Workflow](https://github.com/dlebauer/bety/wiki/Data_Entry_Workflow).

## 1. Overview
This the userguide for entering data into the BETYdb database. The goal of this guide is to provide a consistent method of data entry that is transparent, reproducible, and well documented. The steps here generally accomplish one of two goals. The first goal is to provide data in a consistent framework that is associated with the experimental methods, species, site, and other factors associated with the original study. The second goal is to provide a record of all the transformations, assumptions, and data extraction steps used to migrate data from the primary literature to the standardized framework of the database. This second goal not only supports the scientific value of the data itself, it also simplifies the Quality Assurance process. 

## 2. Using Mendeley
Mendeley provides a central location of the collection, annotation, and tracking of the journal articles that we use. Features of Mendeley that are useful to us include: 
* Collaborative annotation & notes sharing: see section 2.2
    * Text highlighter   
    * Sticky notes for comments in the text
    * Notes field for text notes in the reference documentation
* Read/ unread & favorites:
Papers can be marked as **read** or **unread**, and may be **stared.**
* Groups: see section 2.1
* Tagging

### 2.1 Creating a new group on Mendeley (Project Managers)
Each project has two groups, "projectname" and "projectname_out" for the papers with data to be entered and the papers with data that has been entered. Papers in the _out group may contain data for future entry, for example, traits that are not listed in Table 6.  

Each project manager may have one or more projects, each project should have one group. Group names should refer to plant species, plant functional types, or another project specific name. A list of current groups can be found in Table 1. Please make sure that, at a minimum, Mike Dietze and David LeBauer are invited to join each project folder. 
   1. Open Mendeley desktop
   2. Click `Edit` → `Create Group` or `Ctrl+Shift+M`
   3. Create group name following instructions above
   4. Enter group name 
   5. Set `Privacy Settings` → `Private`
   6. Click `Create Group`
   7. Click `Edit → Settings`
   8. Check File `Synchronization` → `Download attached files to group`

### 2.2 Adding and annotating papers (Project Managers)

The ’tag’ field associated with each paper can be used to further
separate papers, for example by species, or the type of data (’trait’,
’yield’, ’photosynthesis’) that they contain. When naming a group,
folders so that instructions for a technician would include the folder
and the tag to look for, e.g. "please enter data from projectx" or
"please enter data from papers tagged y from project x".

To access the full text and pdf of papers from off campus, use the [UIUC
VPN](http://www.cites.illinois.edu/vpn/download-install.html) service.

If you are managing a Mendeley folder that undergraduates are actively
entering data from, please plan to spend between 15 min and 1 hour per
week maintaining it - enough to keep up with the work that the
undergraduates are doing.

#### 2.2.1 Adding a reference to Mendeley

-   If the DOI number is available (most articles since 2000)
    1.  Select project folder
    2.  Add entry manually
    3.  Paste DOI number in *DOI* field
    4.  Select the search spyglass icon
    5.  Drag and drop pdf onto the record.
-   If DOI not available:
    1.  Download the paper and save as `citation_key.pdf`
    2.  Add using the *Files* field
    3.  The citation key should be in `authorYYYYabc` where `YYYY` is
        the four digit year and `abc` is the acronym for the first three
        words excluding articles (the, a, an), prepositions (on, in,
        from, for, to, etc...), and the conjunctions (for, and, nor,
        but, or, yet, so) with less than three letters.

#### 2.2.2 Annotating a Reference in Mendeley

Each week, please identify and prepare papers that you would like to be
entered next by completing the following steps:
1.  Use the star label to identify the papers that you want the student
    to focus on next.
    -   Start by keeping a minimum of 2 and a maximum of 5 highlighted
        at once so that students can focus on the ones that you want.
        Students have been entering 1-3 papers per week, once we get
        closer to 3-5, the min/max should change.
    -   Choose papers the papers that are the most data rich.
2.  For each paper, use comment bubbles, notes field, and highlighter to
    indicate:
* Name(s) of traits to be collected
* Methods:
    * Site name
    * Location
    * Number of replicates
    * Statistics to collect
    * Identify treatment(s) and control
    * Indicate if study was conducted in greenhouse, pot, or growth chamber  
* Data to collect
    * Identify figures number and the symbols to extract data from.
    * Table number and columns with data to collect
* Covariates
* Management data (for yields)
* Units in 'to' and 'from' fields of used to convert data
* Esoteric information that other scientists or technicians might not catch and that are not otherwise recorded in the database
* Any data that may be useful at a later date but that can be skipped for now.

**Comment or Highlight**

* Sample size
* Covariates (see Table 7)
* Treatments
* Managements
* Other information entered into the database, e.g. experimental details

### 2.3 Finding a citation in Mendeley

To find a citation in Mendeley, go to the project folder. Group folders
and personel are listed in Table 1. By default, data entry technicians should
enter data from papers which have been indicated by a yellow star and in
the order that they were added to the list. Information and data to be
collected from paper can be found under the 'Notes' tab and in
highlighted sections of the paper.

## 3. Google Spreadsheets: Recording data transformations
Google Spreadsheets are used to keep a record of any data that is not
entered directly from the original publication.

* Any raw data that is not directly entered into the database but that
    is used to derive data or stats using equations in Table 1 and Table 5.
* Any data extracted from figures, along with the figure number
* Any calculations that were made. These calculations should be
    included in the cells.

Each project has a google document spreadsheet with the title
’’project\_data’’. In this spreadsheet, each reference should have a
separate worksheet labeled with the citation key (`authorYYYabc`
format). Do not enter data into excel first, this is prone to errors and
information such as equations may be lost when uploading or
copy-pasting.

## 4. Redmine: Reporting errors, suggesting features
### 4.1 Reporting errors in Redmine 
### 4.2 Suggesting features in Redmine

## 5. BETYdb: Entering new data through the web interface
Before entering data, it is first necessary to (add and) select the
citation that is the source of the data. It is also necessary for each
data point to be associated with a Site, Treatment, and Species.
Cultivar information is also required when available, but is only
relevant for domesticated species. Fields with an asterix (\*) are
required.

