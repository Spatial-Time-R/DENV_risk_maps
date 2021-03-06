# Estimate foi for each 20 km square of the dataset disaggregated from the entire original foi dataset

library(ranger)

source(file.path("R", "random_forest", "fit_ranger_RF_and_make_predictions.R"))
source(file.path("R", "utility_functions.R"))  


# define parameters ----------------------------------------------------------- 


parameters <- list(
  dependent_variable = "Z",
  no_predictors = 26)   

aggr_dts_name <- "env_vars_20km.rds"

out_fl_nm <- "covariates_and_foi_20km.rds"

model_obj_nm <- "all_data.rds"


# define variables ------------------------------------------------------------


out_pth <- file.path("output", 
                     "EM_algorithm", 
                     "best_fit_models",
                     paste0("env_variables_", parameters$dependent_variable, "_fit"))
  

# load data -------------------------------------------------------------------


RF_obj <- readRDS(file.path("output",
                            "EM_algorithm",
                            "best_fit_models",
                            paste0("model_objects_", parameters$dependent_variable, "_fit"),
                            model_obj_nm))

pxl_data <- readRDS(file.path("output", 
                              "EM_algorithm",
                              "best_fit_models",
                              "env_variables", 
                              aggr_dts_name))

predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection",
                                     "stepwise_v3",
                                     "predictor_rank.csv"), 
                           stringsAsFactors = FALSE)


# pre processing --------------------------------------------------------------


my_predictors <- predictor_rank$name[1:parameters$no_predictors]


# submit job ------------------------------------------------------------------ 


p_i <- make_ranger_predictions(
  mod_obj = RF_obj, 
  dataset = pxl_data, 
  sel_preds = my_predictors)

pxl_data$p_i <- p_i

write_out_rds(pxl_data, out_pth, out_fl_nm)
