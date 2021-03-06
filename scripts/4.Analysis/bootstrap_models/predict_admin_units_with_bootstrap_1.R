# Load back square predictions for the world, for each model fit 
# Save a n squares x n fits matrix. 

options(didehpc.cluster = "fi--didemrchnb")

my_resources <- c(
  file.path("R", "random_forest", "fit_ranger_RF_and_make_predictions.R"),
  file.path("R", "prepare_datasets", "average_up.R"),
  file.path("R", "utility_functions.R"))

my_pkgs <- c("ranger", "dplyr")

context::context_log_start()
ctx <- context::context_save(path = "context",
                             packages = my_pkgs,
                             sources = my_resources)

context::context_load(ctx)


# define parameters ----------------------------------------------------------- 


parameters <- list(
  id = 24,
  foi_offset = 0.03,
  no_samples = 200) 

out_fl_nm <- "response.rds"

base_info <- c("cell", "latitude", "longitude", "population", "ID_0", "ID_1", "ID_2")

grp_fields <- c("ID_0", "ID_1")


# define variables ------------------------------------------------------------


model_type <- paste0("model_", parameters$id)

foi_offset <- parameters$foi_offset

global_predictions_in_path <- file.path("output", 
                                        "predictions_world",
                                        "bootstrap_models",
                                        model_type,
                                        "boot_samples")

out_pt <- file.path("output", 
                    "predictions_world", 
                    "bootstrap_models",
                    model_type,
                    "adm_1")


# load data -------------------------------------------------------------------


all_sqr_covariates <- readRDS(file.path("output", 
                                        "env_variables", 
                                        "all_squares_env_var_0_1667_deg.rds"))

fct_comb <- read.csv(file.path("output", 
                               "EM_algorithm", 
                               "bootstrap_models", 
                               "boostrap_fit_experiments_uni.csv"))


# pre processing -------------------------------------------------------------- 


var_to_fit <- fct_comb[fct_comb$exp_id == parameters$id, "var"]

fi <- list.files(global_predictions_in_path, 
                 pattern = "^sample",
                 full.names = TRUE)

all_samples <- loop(fi, readRDS, parallel = FALSE)


# combine all results together ------------------------------------------------ 


sqr_preds <- do.call("cbind", all_samples)

if(var_to_fit =="FOI"){
  
  sqr_preds <- sqr_preds - foi_offset
  
}

sqr_preds[sqr_preds < 0] <- 0

sqr_preds <- cbind(all_sqr_covariates[, base_info], sqr_preds)

col_ids <- as.character(seq_len(parameters$no_samples))
  
test <- lapply(col_ids, multi_col_average_up, sqr_preds, grp_fields)

test2 <- lapply(test, "[[", 3)

all_adm_pred <- do.call("cbind", test2)

all_adm_pred <- cbind(test[[1]][, c(grp_fields, "population")], all_adm_pred)

write_out_rds(all_adm_pred, out_pt, out_fl_nm)  
