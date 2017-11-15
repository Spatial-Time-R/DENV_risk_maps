wrapper_to_ggplot_map <- function(
  x, my_colors, model_tp, 
  country_shp, shp_fort, out_path, 
  plot_wdt, plot_hgt){
  
  
  # ---------------------------------------- define parameters / variables
  
  
  var <- x$var 
  scenario_id <- x$scenario_id
  statsc <- x$statistic  
  
  gr_size <- 20
  
  res <- (1 / 120) * gr_size
  
  lats <- seq(-90, 90, by = res)
  lons <- seq(-180, 180, by = res)
  
  j <- 2
  
  col <- my_colors[[j]]
  
  if(statsc == "mean"){
    ttl <- "mean"
  }
  if(statsc == "sd"){
    ttl <- "SD"
  }
  if(statsc == "interv"){
    ttl <- "quantile_diff"
  }
  if(statsc == "lCI"){
    ttl <- "2.5_quantile"
  }
  if(statsc == "uCI"){
    ttl <- "97.5_quantile"
  }
  
  
  # ---------------------------------------- load data 
  
  
  if(var == "FOI"){
    
    base_info <- c("cell", "lat.grid", "long.grid", "population", "ADM_0", "ADM_1", "ADM_2")
    
    out_fl_nm <- paste0(statsc, "_", var,"_0_1667_deg.png")
    
    mean_pred_fl_nm <- paste0(var, "_mean_all_squares_0_1667_deg.rds")
    
    mean_preds <- readRDS(
      file.path(
        "output",
        "predictions_world",
        model_tp,
        "means",
        mean_pred_fl_nm))
    
    all_sqr_covariates <- readRDS(
      file.path(
        "output", 
        "env_variables", 
        "all_squares_env_var_0_1667_deg.rds"))
    
    df_long <- cbind(all_sqr_covariates[, base_info], mean_preds)
    
  } else {
    
    out_fl_nm <- paste0(statsc, "_", var, "_0_1667_deg_", scenario_id, ".png")
    
    mean_pred_fl_nm <- paste0(var, "_mean_all_squares_0_1667_deg_", scenario_id, ".rds")
    
    df_long <- readRDS(
      file.path(
        "output",
        "predictions_world",
        model_tp,
        "means",
        mean_pred_fl_nm))
  
  }

  
  # ---------------------------------------- calculate quantile difference 
  
  
  #df_long$interv <- df_long$uCI - df_long$lCI 
  
  
  # ---------------------------------------- create matrix of values
  
  
  df_long$lat.int=floor(df_long$lat.grid*6+0.5)
  df_long$long.int=floor(df_long$long.grid*6+0.5)
  
  lats.int=lats*6
  lons.int=lons*6
  
  mat <- matrix(0, nrow = length(lons), ncol = length(lats))
  
  i.lat <- findInterval(df_long$lat.int, lats.int)
  i.lon <- findInterval(df_long$long.int, lons.int)
  
  mat[cbind(i.lon, i.lat)] <- df_long[, statsc]
  

  # ---------------------------------------- convert matrix to raster object
  
  
  mat_ls <- list(x = lons,
                 y = lats,
                 z = mat)
  
  r_mat <- raster(mat_ls)
  
  
  #----------------------------------------- get raster extent 
  
  
  my_ext <- matrix(r_mat@extent[], nrow = 2, byrow = TRUE) 
  
  
  # ---------------------------------------- apply same extent to the shape file 
  
  
  country_shp@bbox <- my_ext
  
  
  # ---------------------------------------- mask the raster to the shape file
  
  
  r_mat_msk <- mask(r_mat, country_shp)
  
  
  # ---------------------------------------- convert to ggplot-friendly objects 
  
  
  r_spdf <- as(r_mat_msk, "SpatialPixelsDataFrame")
  
  r_df <- as.data.frame(r_spdf)
  
  
  # ---------------------------------------- plot differently NA values
  
  
  if(var == "R0_r" & statsc == "mean") {
    
    na_cutoff <- 1 
  
  } else {
  
    na_cutoff <- 0  
  
  }  
  
  r_df$layer[r_df$layer < na_cutoff] <- NA 
  
  
  # ---------------------------------------- make map 
  

  map_data_pixel_ggplot(df = r_df, 
                        shp = shp_fort, 
                        out_path = out_path, 
                        out_file_name = out_fl_nm,
                        my_col = col, 
                        ttl = ttl,
                        plot_wdt = plot_wdt, 
                        plot_hgt = plot_hgt,
                        statsc = statsc)
  
}

map_data_pixel_ggplot <- function(df, shp, out_path, out_file_name, my_col, ttl, plot_wdt, plot_hgt, statsc) {
  
  #browser()
  
  dir.create(out_path, FALSE, TRUE)
  
  png(file.path(out_path, out_file_name),
      width = plot_wdt,
      height = plot_hgt,
      units = "in",
      pointsize = 12,
      res = 300)
  
  if(statsc == "p9"){
    
    df$layer1 <- cut(df$layer, breaks = c(-Inf, 50, 70, Inf), right = FALSE)
    
    p <- ggplot() + 
      geom_tile(data = df, aes(x = x, y = y, fill = layer1)) +
      scale_fill_manual(values = my_col,
                        labels = c("< 50", "50-70", "> 70"),
                        guide = guide_legend(title = ttl, 
                                             keywidth = 4, 
                                             keyheight = 5))
  } else {
    
    p <- ggplot() +
      geom_tile(data = df, aes(x = x, y = y, fill = layer)) +
      scale_fill_gradientn(colours = my_col, 
                           guide = guide_colourbar(title = ttl, 
                                                   barwidth = dev.size()[1] * 0.15, 
                                                   barheight = dev.size()[1] * 0.7),
                           na.value = "grey70")
    
  }
  
  p2 <- p + geom_path(data = shp,
                      aes(x = long, y = lat, group = group),
                      colour = "gray40",
                      size = 0.1) +                                             # or: 0.3
    coord_equal() +
    scale_x_continuous(labels = NULL, limits = c(-180, 180), expand = c(0, 0)) +
    scale_y_continuous(labels = NULL, limits = c(-60, 90), expand = c(0, 0)) +
    theme_void() + 
    theme(axis.text.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks = element_blank(),
          plot.margin = unit(c(0, 0, 0, -0.09), "cm"),
          legend.position = c(dev.size()[1] * 0.015, dev.size()[1] * 0.02),    # or: c(0.005, 0.008) 
          legend.text = element_text(size = 15),                               # or: 25
          legend.title = element_text(face = "bold", size = 22))#,             # or: 30
  #legend.background = element_rect(fill = alpha("white", 0.2), colour = "gray50"),
  #panel.background = element_rect(fill = "#A6CEE3", colour = NA)) # lightblue2
  
  print(p2)
  
  dev.off()
  
}
