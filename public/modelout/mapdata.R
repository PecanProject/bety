
### Get access to database
library(PEcAn.DB)
dbsettings <- list(userid = "bety",
                   passwd = "bety",
                   location = "localhost",
                   name = "bety")
newconfn <- function() query.base.con(dbsettings)
### get contents of location_yields
query.base("select * from location_yields;", con = newconfn())

### Load Files
county_files <- dir(pattern="county")
grid_files   <- dir(pattern="grid")
all <- read.csv("all_yield_and_cost_county.csv")

location_yields <- data.frame(#id = "NULL",#1:3109*9,
                              yield = as.numeric(c(as.matrix(all[,c(5:12,14)]))),
                              species = rep(colnames(all)[c(5:12,14)], each = 3109),
                              county_id = rep(all$County_FIPS, 9))
location_yields <- location_yields[-21294,] ## outlier 108767.7
write.csv(location_yields, "location_yields.csv", row.names = FALSE)

# load data infile '/tmp/location_yields.csv' into table location_yields fields terminated by "," optionally enclosed by '"' ignore 1 lines (yield,species,county_id);

### new table with species, lat, lon, variable_id, value
source("~/R-dev/gcs/inst/load-all.R")
x <- cbind(id = 1:nrow(all.long),
           all.long[,c( "lat", "lon", "sp")],
           specie_id = ifelse(all.long$sp == "pavi", 938, ifelse(all.long$sp == "mxg", 1477, 32678)),
           variable_id = 470, value = all.long$aet)
colnames(x) <- c("id", "lat", "long", "species", "specie_id", "variable_id", "value")  
write.csv(x, "~/betydb_redesign/public/temp_models/point_output.csv", row.names = FALSE)
