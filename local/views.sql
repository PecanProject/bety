drop view if exists seeding;
create view seeding  as select treatment_id, management_id, mgmttype, date, level, units from managements as m join managements_treatments as mt on m.id = mt.management_id where mgmttype in ('seeding', 'seed_density', 'row_spacing');
drop view if exists coppice;
create view coppice as select treatment_id, management_id, mgmttype, date, level, units from managements as m join managements_treatments as mt on m.id = mt.management_id where mgmttype in ('coppice');
drop view if exists planting;
create view planting as select treatment_id, management_id, mgmttype, date, level, units from managements as m join managements_treatments as mt on m.id = mt.management_id where mgmttype in ('planting');
drop view if exists mgmtview;  
create view mgmtview as select yields.id as yield_id, planting.date as planting, seeding.date as seeding, coppice.date as coppice from yields left outer join planting on yields.treatment_id = planting.treatment_id left outer join seeding on yields.treatment_id = seeding.treatment_id left outer join coppice on yields.treatment_id = coppice.treatment_id; 

drop view if exists yieldsview;
create view yieldsview as select yields.id as yield_id, yields.citation_id, yields.site_id, yields.treatment_id, sites.sitename as site, sites.city, sites.lat, sites.lon,  species.scientificname, species.genus, citations.author as author, citations.year as cityear, treatments.name as trt, date, month(date) as month, year(date) as year, mean, n, statname, stat, yields.notes, users.name as user, planting, seeding from yields left join sites on yields.site_id = sites.id left join species on yields.specie_id = species.id left join citations on yields.citation_id = citations.id left join treatments on yields.treatment_id = treatments.id left join users on yields.user_id = users.id left join mgmtview on yields.id = mgmtview.yield_id;


drop view if exists traitsview;
create view traitsview as select traits.id as trait_id, traits.citation_id, traits.site_id, traits.treatment_id, sites.sitename as site, sites.city, sites.lat, sites.lon, species.scientificname, species.genus, citations.author as author, citations.year as cityear, treatments.name as trt, date, month(date) as month, year(date) as year, variables.name as trait, mean, n, statname, stat, traits.notes, users.name as user from traits left join sites on traits.site_id = sites.id left join species on traits.specie_id = species.id left join citations on traits.citation_id = citations.id left join treatments on traits.treatment_id = treatments.id left join variables on traits.variable_id = variables.id left join users on traits.user_id = users.id;

