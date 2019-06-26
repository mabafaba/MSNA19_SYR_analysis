# setup

library(dplyr)
library(koboquest) # manage kobo questionnairs
library(kobostandards) # check inputs for inconsistencies
library(xlsformfill) # generate fake data for kobo
library(hypegrammaR) # simple stats 4 complex samples
library(composr) # horziontal operations
library(tidyr)

# loading useful functions from files

source("functions/to_alphanumeric_lowercase.R")
source("functions/analysisplan_factory.R")
source("functions/results_handling.R")

### LOADING AND PREPROCESSING INPUTS 

# load questionnaire questions sheet
questions <- read.csv("input/questionnaire_questions.csv", 
                      stringsAsFactors=F, check.names=F)


# double check for inconsistencies
questionnaire_issues<-check_input(questions = questions, choices = choices)
questionnaire_issues %>% write.csv("./output/issues_with_questionnaire.csv")
browseURL("./output/issues_with_questionnaire.csv")


# preprocessing questions sheet
# ...

# Choices sheet
choices <- read.csv("input/questionnaire_choices.csv", 
                    stringsAsFactors=F, check.names=F)
# remove empty columns
choices <- choices[, colnames(choices)!=""]

# preprocessing choices sheet
# ...

# Prepare standardised "questionnaire" object
questionnaire <- load_questionnaire(response,questions,choices)

# Sampling frame
samplingframe <- load_samplingframe("./input/sf.csv")

# preprocessing sampling frame... (usually: make long format and add stratum ID)

# make samplingframe tidy (one row per stratum)
samplingframe_tidy <- samplingframe %>% gather(key = "population_group", # define new column name for column containing original column names
                                               value = "population", # define new column name for values of all columns below
                                               nondisplaced, # columns to "gather" into a single column:
                                               idps,
                                               returnees,
                                               refugees,
                                               migrants) %>%

  select(...) # select interesting columns only


# add stratum id to sampling frame: a sigle colum that uniquely identifies the stratum (location and population group)
# this id must be producible in the dataset with exact matches.
# Ususally this means concatenating ("pasting") population group and location
# We use "mutate" which adds a new variable based on existing variables
samplingframe_tidy<- samplingframe_tidy %>% mutate(stratum_id = paste0(district.pcode,"_",population_group))


# Data: from CSV or automatically generated
# generate data
# response <- read.csv("./input/main_dataset_v2.csv", stringsAsFactors = F)

response <- xlsform_fill(questions,choices,10000,check.names = T)
# names(response)<- koboquest:::to_alphanumeric_lowercase(names(response))

# add cluster ids
# ...

# horizontal operations / recoding
# ...

# vertical operations / aggregation



# add matching stratum id to data: recode population group and concatenate with p code 
response <- response %>%
  new_recoding(data_stratum_id,source = a1_metadata) %>%
  recode_to("nondisplaced",where.selected.any = "a1_1") %>% 
  recode_to("refugees",where.selected.any = "a1_2") %>% 
  recode_to("idps",where.selected.any = "a1_3") %>% 
  # recode_to("???",where.selected.any = "a1_4") %>%
  # recode_to("???",where.selected.any = "a1_5") %>% 
  end_recoding()

response <- response %>% mutate(data_stratum_id = paste0("YE",a3_metadata,"_",data_stratum_id))  

# percent matched in samplingframe?
# note that for real data this will of course be different
cat(crayon::red(mean(response$data_stratum_id %in% samplingframe_tidy$stratum_id) %>% multiply_by(100) %>% round(2) %>% paste0("% of records matched in samplingframe")))


# make an analysisplan including all questions as dependent variable by HH type:


analysisplan<-make_analysisplan_all_vars(response,
                                         questionnaire
                                         ,independent.variable = "a1_metadata"
                                         #, repeat.for.variable = "a4_metadata"
)

# remove metadata we're not interested in analysing
analysisplan<-analysisplan %>% 
  filter(!grepl("metadata|start$|end$|deviceid$|uuid",dependent.variable)) 



# Data that does not match any stratum can not be analysed, so removing it.
# First we check how many those are:
message(paste("% of strata not matched:",
              (length(which(!(response$data_stratum_id %in% samplingframe_tidy$stratum_id)))/nrow(response))))

response <- response %>% 
  filter(data_stratum_id %in% samplingframe_tidy$stratum_id)


# create a weighting function from the sampling frame

strata_weights <- map_to_weighting(sampling.frame = samplingframe_tidy,
                                   sampling.frame.population.column = "population",
                                   sampling.frame.stratum.column = "stratum_id",
                                   data.stratum.column = "data_stratum_id")


# before running the analysis, double check for inconsistencies in the inputs:

input_inconsistencies <-kobostandards::check_input(data = response,
                           questions = questions,
                           choices = choices,
                           samplingframe = samplingframe_tidy,
                           analysisplan = analysisplan)
write.csv(input_inconsistencies, "./output/input_inconsistencies.csv")

# ACTUAL ANALYSIS 

results <- from_analysisplan_map_to_output(response, analysisplan = analysisplan[1:20,],
                                           weighting = strata_weight_fun,
                                           cluster_variable_name = NULL,
                                           questionnaire)


# OUTPUT RESULTS

map_to_hierarchical_template(results,
                             questionnaire = questionnaire,
                             by_analysisplan_columns =c("dependent.var"
                                                        # ,"repeat.var"
                                                        # ,"repeat.var.value"
                                                        # ,"independent.var",
                                                        # ,"independent.var.value"
                             ),
                             filename = "./output/test.html")


browseURL("./output/test.html")

map_to_master_table(results,"test.csv")






