# For each bootstrap sample of the original dataset, it creates a scatter plot of:  
#
# 1) admin unit observation vs admin unit prediction 
# 2) admin unit observation vs population weighted average of the square predictions (within admin unit)
# 3) admin unit observation vs population weighted average of the 1 km pixel predictions (within admin unit)
#
# NOTE: 1, 2 and 3 are for train and test sets separately (total of 6 plots)

library(reshape2)
library(ggplot2)
library(plyr)

source(file.path("R", "random_forest", "RF_preds_vs_obs_stratified_plot.r"))
source(file.path("R", "random_forest", "get_lm_equation.r"))


# ---------------------------------------- define parameters 


no_fits <- 50
no_datapoints <- 433

model_type <- "boot_model_20km_cw"

in_path <- file.path(
  "output",
  "EM_algorithm",
  model_type,
  "predictions_data") 

out_path <- file.path(
  "figures",
  "EM_algorithm",
  model_type,
  "scatter_plots",
  "boot_samples")
  
out_path_av <- file.path(
  "figures",
  "EM_algorithm",
  model_type,
  "scatter_plots")


# ---------------------------------------- create objects for matrix algebric operations


all_adm_preds <- matrix(0, nrow = no_datapoints, ncol = no_fits)
all_sqr_preds <- matrix(0, nrow = no_datapoints, ncol = no_fits)
#all_pxl_preds <- matrix(0, nrow = no_datapoints, ncol = no_fits)
train_ids <- matrix(0, nrow = no_datapoints, ncol = no_fits)
test_ids <- matrix(0, nrow = no_datapoints, ncol = no_fits)
  

# ---------------------------------------- run


for (i in seq_len(no_fits)) {
  
  dts_nm <- paste0("all_scale_predictions_", i, ".rds")
  
  dts <- readRDS(file.path(in_path, dts_nm))
  
    
  #####
  
  all_adm_preds[,i] <- dts$adm_pred
  all_sqr_preds[,i] <- dts$mean_square_pred
  #all_pxl_preds[,i] <- dts$mean_pxl_pred
  train_ids[,i] <- dts$train
  test_ids[,i] <- 1 - dts$train
  
  #####
  
  
  names(dts)[names(dts) == "train"] <- "dataset"
  
  dts$dataset <- factor(x = dts$dataset, levels = c(1, 0), labels = c("train", "test"))
  
  # rotate df from wide to long to allow faceting
  dts_mlt <- melt(
    dts, 
    id.vars = c("data_id", "ADM_0", "ADM_1", "o_j", "dataset"),
    measure.vars = c("adm_pred", "mean_square_pred"),
    variable.name = "scale")
  
  fl_nm <- paste0("pred_vs_obs_plot_sample_", i,".png")
  
  RF_preds_vs_obs_plot_stratif(
    df = dts_mlt,
    x = "o_j",
    y = "value",
    facet_var = "scale",
    file_name = fl_nm,
    file_path = out_path)

}


# ---------------------------------------- calculate the mean across fits of the predictions (adm, sqr and pxl) 
# ---------------------------------------- by train and test dataset separately


train_sets_n <- rowSums(train_ids)
test_sets_n <- rowSums(test_ids)

mean_adm_pred_train <- rowSums(all_adm_preds * train_ids) / train_sets_n
mean_adm_pred_test <- rowSums(all_adm_preds * test_ids) / test_sets_n

mean_sqr_pred_train <- rowSums(all_sqr_preds * train_ids) / train_sets_n
mean_sqr_pred_test <- rowSums(all_sqr_preds * test_ids) / test_sets_n

#mean_pxl_pred_train <- rowSums(all_pxl_preds * train_ids) / train_sets_n
#mean_pxl_pred_test <- rowSums(all_pxl_preds * test_ids) / test_sets_n

av_train_preds <- data.frame(dts[,c("data_id", "ADM_0", "ADM_1", "o_j")],
                             admin = mean_adm_pred_train,
                             square = mean_sqr_pred_train,
                             #pixel = mean_pxl_pred_train,
                             dataset = "train")

av_test_preds <- data.frame(dts[,c("data_id", "ADM_0", "ADM_1", "o_j")],
                            admin = mean_adm_pred_test,
                            square = mean_sqr_pred_test,
                            #pixel = mean_pxl_pred_test,
                            dataset = "test")

all_av_preds <- rbind(av_train_preds, av_test_preds)
  
all_av_preds_mlt <- melt(
  all_av_preds, 
  id.vars = c("data_id", "ADM_0", "ADM_1", "o_j", "dataset"),
  measure.vars = c("admin", "square"),
  variable.name = "scale")

fl_nm_av <- paste0("pred_vs_obs_plot_averages.png")

RF_preds_vs_obs_plot_stratif(
  df = all_av_preds_mlt,
  x = "o_j",
  y = "value",
  facet_var = "scale",
  file_name = fl_nm_av,
  file_path = out_path_av)

# percentiles_train <- t(apply(produc_train, 1, quantile, probs = c(0.025, 0.975)))
# percentiles_test <- t(apply(produc_test, 1, quantile, probs = c(0.025, 0.975)))
# colnames(percentiles_train) <- c("low_perc_train", "up_perc_train")
# colnames(percentiles_test) <- c("low_perc_test", "up_perc_test")