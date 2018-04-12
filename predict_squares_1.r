# Makes predictions for all the squares in the world.

options(didehpc.cluster = "fi--didemrchnb")

my_resources <- c(
  file.path("R", "utility_functions.r"),
  file.path("R", "random_forest", "fit_h2o_RF_and_make_predictions.r"),
  file.path("R", "plotting", "functions_for_plotting_square_level_maps.r"))
  
my_pkgs <- "h2o"

context::context_log_start()
ctx <- context::context_save(path = "context",
                             packages = my_pkgs,
                             sources = my_resources)


# define parameters ----------------------------------------------------------- 


var_to_fit <- "FOI"

number_of_predictors <- 9
  
RF_mod_name <- "RF_obj.rds"

base_info <- c("cell", "lat.grid", "long.grid", "population", "ADM_0", "ADM_1", "ADM_2")


# define variables ------------------------------------------------------------


model_tp <- paste0(var_to_fit, "_best_model")

out_pt <- file.path("output", "predictions_world", "best_fit_models", model_tp)
  
out_fl_nm <- "response.rds"


# are you using the cluster? -------------------------------------------------- 


context::context_load(ctx)


# load data ------------------------------------------------------------------- 


all_sqr_covariates <- readRDS(file.path("output", 
                                        "env_variables", 
                                        "all_squares_env_var_0_1667_deg.rds"))

RF_obj_path <- file.path("output",
                         "EM_algorithm",
                         "best_fit_models",
                         model_tp,
                         "optimized_model_objects")

# predicting variable rank
predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection", 
                                     "metropolis_hastings", 
                                     "exp_1", 
                                     "variable_rank_final_fits_exp_1.csv"),
                           stringsAsFactors = FALSE)


# get best predictor ---------------------------------------------------------- 


my_predictors <- predictor_rank$name[1:number_of_predictors]


# submit one job -------------------------------------------------------------- 


h2o.init()

RF_obj <- h2o.loadModel(file.path(RF_obj_path, RF_mod_name))

p_i <- make_h2o_predictions(RF_obj, all_sqr_covariates, my_predictors)

h2o.shutdown(prompt = FALSE)

p_i[p_i < 0] <- 0

world_sqr_preds <- cbind(all_sqr_covariates[, base_info], best = p_i)

write_out_rds(world_sqr_preds, out_pt, out_fl_nm)  
