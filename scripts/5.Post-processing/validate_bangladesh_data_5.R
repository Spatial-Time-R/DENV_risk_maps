
# load the original foi dataset
# fit a RF model to the dataset and make predictions 
# calculate correlation between observed and predicted value of the 7 points 

library(h2o)
library(ggplot2)

source(file.path("R", "random_forest", "fit_h2o_RF_and_make_predictions.R"))
source(file.path("R", "prepare_datasets", "set_pseudo_abs_weights.R"))


# define parameters -----------------------------------------------------------


var_fit <- "FOI"
pseudoAbs_value <- -0.02
all_wgt <- 1
wgt_limits <- c(1, 500)
no_trees <- 500
min_node_size <- 20
no_predictors <- 9  

plot_out_pt <- file.path("figures", "data", "salje")

plot_ttl <- "yes salje points in training & yes log_pop"

foi_dts_name <- "All_FOI_estimates_linear_env_var_area_salje.csv"

plot_out_name <- "correlation_adm_pred_vs_observations_4.png"

extra_predictors <- "log_pop_den"


# load data -------------------------------------------------------------------


all_foi <- read.csv(file.path("output", "foi", foi_dts_name),
                    stringsAsFactors = FALSE) 

all_foi_salje <- read.csv(file.path("output", "foi", "All_FOI_estimates_linear_env_var_area_salje.csv"),
                    stringsAsFactors = FALSE) 

predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection", 
                                     "metropolis_hastings", 
                                     "exp_1", 
                                     "variable_rank_final_fits_exp_1.csv"),
                           stringsAsFactors = FALSE)


# pre process -----------------------------------------------------------------


salje_data <- all_foi_salje[all_foi_salje$ISO == "BGD", ]
salje_data <- salje_data[-1, ] # the first bangladesh point is from Natsuko  

all_foi[all_foi$type == "pseudoAbsence", var_fit] <- pseudoAbs_value

all_foi$new_weight <- all_wgt
pAbs_wgt <- get_area_scaled_wgts(all_foi, wgt_limits)
all_foi[all_foi$type == "pseudoAbsence", "new_weight"] <- pAbs_wgt

# choose the predictors
my_predictors <- predictor_rank$name[1:no_predictors]
my_predictors <- c(my_predictors, extra_predictors)


# fit -------------------------------------------------------------------------


training_dataset <- all_foi[, c(var_fit, my_predictors, "new_weight")]

h2o.init()

RF_obj <- fit_h2o_RF(dependent_variable = var_fit, 
                     predictors = my_predictors, 
                     training_dataset = training_dataset, 
                     no_trees = no_trees, 
                     min_node_size = min_node_size,
                     my_weights = "new_weight",
                     model_nm = "test")

salje_data$p_i <- make_h2o_predictions(RF_obj, salje_data, my_predictors)

h2o.shutdown(prompt = FALSE)

salje_data$p_i[salje_data$p_i < 0] <- 0


# plot ------------------------------------------------------------------------


corr_coeff <- round(cor(salje_data$FOI, salje_data$p_i), 3)

p <- ggplot() +
  geom_point(aes(x = FOI, y = p_i, colour = "red"), data = salje_data, size = 1) +
  scale_colour_identity(name = "", guide = "legend", labels = "salje") +
  geom_abline(slope = 1, intercept = 0, linetype = 2) +
  geom_text(aes(x = FOI, y = p_i, label = ID_1), data = salje_data, nudge_y = 0.0009) +
  geom_text(aes(x = 0.006, y = 0.004, label = paste0("r = ", corr_coeff))) +
  scale_x_continuous("observed admin 1 FOI", limits = c(0,0.01)) +
  scale_y_continuous("predicted admin 1 FOI", limits = c(0,0.02)) +
  ggtitle(plot_ttl)

ggsave(file.path(plot_out_pt, plot_out_name), 
       p, 
       width = 15, 
       height = 8, 
       units = "cm")
