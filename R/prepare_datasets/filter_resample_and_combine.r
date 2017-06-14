filter_resample_and_combine <- function(
  i, boot_samples, tile_ls, var_names, new_res, 
  my_preds, out_file_path, out_file_name){
  
  foi_data <- boot_samples[[i]]
  
  names(foi_data)[names(foi_data) == "ID_0"] <- "ADM_0"
  names(foi_data)[names(foi_data) == "ID_1"] <- "ADM_1"

  pxl_job <- loop(
    tile_ls,
    filter_and_resample,
    foi_dts = foi_data, 
    env_var_names = var_names, 
    grp_flds = c("data_id", "ADM_0", "ADM_1", "cell", "lat.grid", "long.grid"), 
    grid_size = new_res,
    parallel = TRUE)
  
  pxl_dataset <- do.call("rbind", pxl_job)
  
  pxl_dataset[, my_preds][pxl_dataset[, my_preds] == 0] <- NA
  
  pxl_dataset <- remove_NA_rows(pxl_dataset, my_preds)
  
  pxl_dataset$cell <- seq_len(nrow(pxl_dataset))
  
  names(pxl_dataset)[names(pxl_dataset) == "cell"] <- "square"
  
  a <- out_file_name[i]
  
  write_out_rds(pxl_dataset, out_file_path, a)
  
}