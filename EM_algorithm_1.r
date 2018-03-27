# Filters each 1km tile based on the original foi dataset  
# and resamples each tile to 20km resolution

options(didehpc.cluster = "fi--didemrchnb")

CLUSTER <- TRUE

my_resources <- c(
  file.path("R", "prepare_datasets", "filter_and_resample.r"),
  file.path("R", "prepare_datasets", "clean_and_resample.r"),
  file.path("R", "prepare_datasets", "remove_NA_rows.r"),
  file.path("R", "prepare_datasets", "grid_up.R"),
  file.path("R", "prepare_datasets", "average_up.r"))

my_pkgs <- c("data.table", "dplyr")

context::context_log_start()
ctx <- context::context_save(path = "context",
                             packages = my_pkgs,
                             sources = my_resources)


# define parameters ----------------------------------------------------------- 


resample_grid_size <- 20
  
in_pt <- file.path("output", "env_variables", "all_sets_gadm_codes")

group_fields <- c("data_id", "ADM_0", "ADM_1")


# define variables ------------------------------------------------------------


new_res <- (1 / 120) * resample_grid_size


# are you using the cluster? -------------------------------------------------- 


if (CLUSTER) {
  
  obj <- didehpc::queue_didehpc(ctx)

} else {
  
  context::context_load(ctx)

}


# load data ------------------------------------------------------------------- 


foi_data <- read.csv(
  file.path("output", "foi", "All_FOI_estimates_linear_env_var_area.csv"),
  stringsAsFactors = FALSE)

predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection", 
                                     "stepwise", 
                                     "predictor_rank.csv"),
                           stringsAsFactors = FALSE)


# pre processing -------------------------------------------------------------- 


names(foi_data)[names(foi_data) == "ID_0"] <- "ADM_0"
names(foi_data)[names(foi_data) == "ID_1"] <- "ADM_1"
names(foi_data)[names(foi_data) == "population"] <- "adm_pop"

my_predictors <- predictor_rank$name[1:13]

fi <- list.files(in_pt, pattern = "^tile", full.names = TRUE)


# submit one test job --------------------------------------------------------- 


# t <- obj$enqueue(
#   filter_and_resample(
#     fi[1],
#     foi_dts = foi_data,
#     env_var_names = my_predictors,
#     grp_flds = group_fields,
#     grid_size = new_res))


# submit all jobs ------------------------------------------------------------- 


if (CLUSTER) {

  pxl_job <- queuer::qlapply(
    fi,
    filter_and_resample,
    obj,
    foi_dts = foi_data,
    env_var_names = my_predictors,
    grp_flds = group_fields,
    grid_size = new_res)

} else {

  pxl_job <- lapply(
    fi,
    filter_and_resample,
    foi_dts = foi_data,
    env_var_names = my_predictors,
    grp_flds = group_fields,
    grid_size = new_res)

}
