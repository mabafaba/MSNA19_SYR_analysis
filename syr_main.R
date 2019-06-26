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




questions <- read.csv("./input/questions.csv")

questions$name <- tolower(questions$name)
questions$type <- tolower(questions$type)
questions$required <- tolower(questions$required)
questions$calculation<- tolower(calculation)

choices <- read.csv("./input/choices.csv")
choices$list_name<-tolower(choices$list_name)

