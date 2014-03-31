Ecological Forecasting Workshop
========================

Workflows breakout group
-------------------------------------

SUMMARY AFTER MEETING 1 AND WHOLE GROUP DISCUSSION
Discussion focused on 
        Needs from workflow engines in the future
        Why we haven't adopted a common workflow system
        Standardising across data formats and model input output formats
        Benchmarking models against multiple datasets
        Model intercomparisons
        Red flag systems for when data and model outputs are differing from expected behaviours
        Adding semantics to model and data inputs and outputs and probabilities
        Metadata standards that will work for ecological forecasting

Reproducibility - would motivate adoption; esp. if demanded by journals, funding, reviewers; 
Review Paper topics
* state of reproducibiilty
* best practices data life cycle

NOTES MADE DURING MEETING 1
Topics
Metadata/data standardization and interoperability
how to define and share probabilistic results?
easier to describe 'data' than model output
rOpenSci Getting data into R: what do workflows need?
How can we standardize data formats?
EML (ecological metadata language), NeXML (http://www.nexml.org/)
estimates of uncertainty / data quality
uniform API for multiple sources of data - we're working on this, so far we have 
taxonomy (from e.g., NCBI, ITIS, etc.)
spatial data (from e.g. GBIF, BISON, iNaturalist, etc.)
EML package: can automatically push data and get do
Push to KNB/DataONE/FigShare repositories
R package eml: https://github.com/ropensci/EML
Would it help to write out netcdf files from our NOAA R pkg wrapper to use in other software? And for spatial occurrence data from spocc/rgbif/etc?
Data transformations we could provide? e.g, Interpolation of climate data from NOAA
Kepler modules as frontend to R code
Automated provenance tracking w/in R (e.g. analytic web)
Parallelization of code; access to different scheduler engines; evolving landscape
Workflow branches based on needs of node (e.g. I/O, flops, ram)
helps w/ scalability. 
Uncertainty, multi-scale coupling
how to couple independent codes; model-to-model coupling; transformation
Why one workflow system over another; 
what are common and uncommon requirements for workflow engines
What do we want in a wf engine; 
See comparison paper:
Yu, Jia, and Rajkumar Buyya. "A taxonomy of scientific workflow systems for grid computing." ACM Sigmod Record 34.3 (2005): 44-49.http://arxiv.org/pdf/cs/0503025.pdf

2007 workshop: taverna, triana, kepler. Covered this  question - decided that interoperability was more trouble than it is worth; compatability done by wraping one in another.
Invitro modeling framework (a workflow?) - model interoperability
modularity - componentize complexity
Ptolemy: Models of computation
See: Lee, E. A., and A. Sangiovanni-Vincentelli. 1998. A framework for comparing models of computation. IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems 17:1217–1229. doi:10.1109/43.736561     
The problem of the computational overhead in using workflows
Developing worksflow models for data-constrained models of systems.
Benefit from having a large enough project to work with
e.g bioinformatics -> bioKepler
openTopography.org
R as a workflow itself - this is essentially folks using knitr with markdown or latex - which has very little structure other than separating text from code blocks
Finite  state machine as model to model communication
UVCDat http://uvcdat.llnl.gov/
Bob Cook: MstMIP / model intercomparison
MODEL INTERCOMPARISONS <- one of the key areas of future application
Anticipate key workflow/software needs for 5-10 years time
Workflows as a means to get the community to work together
If ecological forecasting is to become a reality - we need workflows to deliver that
Model component interoperation  - going from molecules to blue whales
Models (and model components) as hypotheses
Benchmarking models <- a perfect place for workflows
Scenario testing
Having WF system handle uncertainty would be useful
Need mechanism to represent model outputs and model performance
Identify translators for model inputs & outputs
e.g. Adopt MSTMIP standards for variables 
merging across scales 
end to end modeling -> is there any meaning to this?
Beth Fulton, Ken Rose
don't do it; not sufficiently adaptable
keep it simple, solve one prob. at a time
keep data in native format rather than homogenize
What are the low hanging fruit?
Optimal levels of complexity in workflow 
also, model complexity
Detection of scale shifts, using scale as object of observation
Auto characterisation of sig changes in ecological data and model predictions.
Identifying red flags in data observations  and model predictions
Transparent / efficient access to data, computing <- ability to combine both in a transparent way
provenance tracking -> captured as reproducible research objects
adopting best practices w/in community
business model to sustain software; combining big, heterogeneous data, 
Lack of willing in community to adopt modularity in multicomponent models of systems
Managing data streams <- big data
Managing large volumes of data < big data
Big data IS an issue in certaiin areas
What are the workflow needs for the next 5-10 years
learnn from past efforts and lessons
Look towards future demands
Data integration and model coupling
almost all existing systems don't deal in semantics
Try to add semantics to modelling frameworks to make it easier to build systems that understand more of the data / information compatabilities specific to the domain.

Day 2 Discussion
-------------------------
Why have so many groups decided to create their own workflow rather than adapt an existing system?
Are ecological demands on wf systems special?
Can we describe model components semantically to provide plug-n-play within wf systems?  
Berkley, C., S. Bowers, M. B. Jones, B. Ludaescher, M. Schildhauer, and J. Tao. 2005. Incorporating Semantics in Scientific Workflow Authoring. Pages 75–78 in J. Frew, editor. Proceedings of the 17th International Conference on Scientific and Statistical Database Management. Santa Barbara, CA.
Madin, J., S. Bowers, M. Schildhauer, S. Krivov, D. Pennington, and F. Villa. 2007. An ontology for describing and synthesizing ecological observation data. Ecological Informatics 2:279–296.
Madin, J. S., S. Bowers, M. P. Schildhauer, and M. B. Jones. 2008. Advancing ecological research with ontologies. Trends in Ecology & Evolution 23:159–68.
What are the key barriers to plug-n-play ecological forecasting?
Getting data providers online to not only provide read, but also write access through open APIs
Provide mechanism to describe a desired standard data product
Can be the target of data transformation as input to a model, or can describe existing raw data to decide which are transformable to that target
Licenses? (e.g., ESA ecological archives has unclear licenses for reuse)
Lack of well-specified interfaces to model components; 
Standard grammars for defining data-data and data-model and model-model interfaces

"Best practices in ecological computing" 
in R: Commit to S4 classes instead of S3, all languages: well-specified APIs, contractual committment
continuous integration e.g. Travis-CI (or is this too high level?)
testing (too high level?)



What do we need to do to up our game, computationally, in producing actionable predictions of ecosystems - data input standards, workflows, probabilities, cloud

Proposal of what to work on
1. High profile perspective on the needs to get towards reproducibility in the prediction of complex multicomponent systems - for which ecological systems are a prime example but Earth System Models are another - and how advances in workflow technology are needed to achieve that - potentially with a section on case study examples of where we really need this reproducibility in order to keep advancing. Tailed by 5-10 year goal for the development of workflow technology to meet the needs of ecological / earth system research.
2. Discuss further how the specifics of conducting multicomponent multi-dataset inference based research raises new challenges for developing workflows.
3. Discuss the challenges of managing multi-component modelling with workflows 
4. A semantics for decribing workflows? Needed? Helpful?


Publishing derived data sets. 
Automated data input and output (e.g. what NEON is working on)

ncML - 

Top 10 blockers/necessary developments to plug-and-play ecosystem forecasting: key development requirements for the next 5-10 years

Achieving greater levels of interoperability:


Paper Outline
---------------------
Titles:
"Reproducibility in ecological and environmental modelling: whether and why scientific workflows, and where next?"
"Software practices that promote interoperability {and reproducibility} for ecological forecasting"

# rhetorical approach framework
## name and define practice
## what do you want to achieve and how to get there
## pros and cons
## examples

Outline/Topics
Intro general background of sw best practices (e.g., White paper), plus acknowledge these are well-established software engineering practices
Discussion of desiridata: Reproducible, Traceable, Usable, Comparable, {Reusable}
define the terms
why are they useful
within context of increasing applied relevance
increased efficiency within research groups
building community: standing on shoulders of giants
Recommended Practices (pros, cons/limitations, benefits, example of use); presented in heirarchy of stages ... 
Version and archive and share code
Gists versus repos versus releases
Use Functions: abstract and generalize, DRY
Example from eco forecasting
Well-specified interfaces (APIs) and modules
Consistent contracts between modules
Hooks for other software to interact
Version control of APIs and modules
Example from eco forecasting
Avoid letting implementation leak into interface
e.g., JAGS requires integer site names for iteration, constraining data inputs
e.g., weather downscaling algorithm that works based on column order or specific naming conventions
Automate data processing (not in Excel)
Auditable, repeatable
Example
De-couple data from code: use data repository APIs, use open, portable data representation formats {like CSV, and NetCDF}
No hard coded paths
Isolate data I/O in separate modules (e.g., a) call to the web, collect raw payload, b) downstream processing)
References to data in *accessible* repository systems (e.g., via DOI)
Deal with access control issues (public versus private examples)
Version control of data (e.g., DataONE, dat, ...)
See diatribes about reasons to share data
Example from eco forecasting
Use a consistent error handling and propagation strategy
Use composable workflow systems (e.g., R, Kepler) to link components
Benefit: reuse and mix and match modules for various applications
Benefit -- documents end-to-end process
Example: Benefit of Automation: show LeBauer example of automation
Document the workflow and process and code
Use literate programming to link implementation to documentation
Doxygen, ROxygen, knitr
write for humans; clear variable names
{Provide License and metadata} - or can we ref this in other papers?
Formally test models
Separate unit and integration testing
Test with a wide variety of data bounds / prevent decline of model skill
Be aware of scaling and integration choices, use broker/wrapper components to couple components that operate at multiple scales or rates
Expose module constraints in documentation
e.g., scale constraints, normality constraints, etc.
Report uncertainty in input and output data
Can we recommend specific uncertaininty representations, or at least list them?
A typology of uncertainty measures, with a serialization approach
Education/Workforce dev and Collaboration topics? 
Need to train EES students e.g., software carpentry as starting point
Build on this with the best practices
Error handling (See recommendation above -- should this be in the recs section?)
useful messages
examples and/or case studies (or integrated into practices above)


DEFINE AUDIENCE AND SCOPE

Day 3
Note from Matthew Smith -

In the absence of me for the next hour or two and in light of the workflows review structure I thought I d share a few thoughts in this thing

I think most people if they think about it can identify what the advantages and disadvantages of workflows are. I am still thinking it would be better to orient any communication around this issue towards saying something much more specific about the particular needs for and from workflows in a few specific areas of ecological forecasting, rather than ecological forecasting/prediction in general.
 
On top of that, rather than a lengthy itemised list I wonder if it would be a more impactful structure if we structure it like a discussion or question and answer paper (like they do at the end of stats papers), or a pro’s and con’s discussion paper. E.g.
 
A discussion around the costs and benefits of workflows for enabling reproducibility and interoperability
Pros 
Cons
 
Where in ecology and environmental science does there appear to be a compelling need?
Pros.
Cons.
 
What is or can be done for improving reproducibility and interoperability in specific parts of the workflow
                Data input output
                Model component interfaces
 
So in conclusion, do we as a group feel certain areas (e.g. the CMIP6 endeavour) really MUST take a lead in defining standards for the data input output and model component  interfaces if they are to achieve their longer term goals and then if we are convinced then what are the, say, key recommendations to be implemented within the next 5-10 years for achieving that. Having a specific nod to CMIP6 would be great.

In conclusion, the target audience and scope would be scientists, developers and funders aiming to contribute to these key areas in ecological forecasting to remind them that they should consider developing the state of the art in our ability to act interoperably and reproduibly in those areas... so that they may adopt some of our recommendations.

-> see you soon



References
-----------------

CF Standards - NetCDF metadata standards for data discovery: https://geo-ide.noaa.gov/wiki/index.php?title=NetCDF_Attribute_Convention_for_Dataset_Discovery

Mandal, N., E. Deelman, G. Mehta, M.-H. Su, K. Vahi, and M. D. Rey. 2007. Integrating Existing Scientific Workflow Systems : The Kepler / Pegasus Example. Information Sciences:21–28.

Wang, J., I. Altintas, C. Berkley, L. Gilbert, and M. B. Jones. 2008. A High-Level Distributed Execution Framework for Scientific Workflows. 2008 IEEE Fourth International Conference on eScience:634–639.

Wang, J., I. Altintas, P. R. Hosseini, D. Barseghian, D. Crawl, C. Berkley, and M. B. Jones. 2009. Accelerating Parameter Sweep Workflows by Utilizing Ad-hoc Network Computing Resources: An Ecological Example. 2009 Congress on Services - I:267–274.
  
Allen Hierarchy: Perspectives for Ecological Complexity 

http://blogs.msdn.com/b/martinca/archive/2009/11/02/microsoft-computational-science-studio.aspx

Coming Soon to a Lab Near You: Drag-and-Drop Virtual Worlds                                         
Robert F. Service
Science 11 February 2011:  669-671. [DOI:10.1126/science.331.6018.669] 

An example of a similar "guidelines" paper; outreach rather than findings:  
Borer, E., E. Seabloom, M. B. Jones, and M. Schildhauer. 2009. Some Simple Guidelines for Effective Data Management. Bulletin of the Ecological Society of America:205–214.  http://dx.doi.org/10.1890/0012-9623-90.2.205

An example of using global change to illustrate changes needed in data management:  
Wolkovich, E. M., J. Regetz, and M. I. O’Connor. 2012. Advances in global change research require open science by individual researchers. Global Change Biology:1–9. doi:10.1111/j.1365-2486.2012.02693.x


  
