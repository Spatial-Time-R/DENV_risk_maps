generic_scatter_plot <- function(df, 
                                 x, 
                                 y,
                                 file_name, 
                                 file_path,
                                 foi_offset) {
  
  # browser()
  
  x_values <- pretty(df[, x], n = 5)
  y_values <- pretty(df[, y], n = 5)
  min_x_value <- min(x_values)
  max_x_value <- max(x_values)
  min_y_value <- min(y_values)
  max_y_value <- max(y_values)
  
  eq <- lm_eqn(df = df, y = y, x = x)
  
  eq_df <- data.frame(eq) 
    
  x_text <- ifelse(max_x_value > 2, 3, min_x_value + (0.3 * max_x_value))
    
  p <- ggplot(df, aes_string(x = x, y = y)) +
    geom_point(aes_string(x = x, y = y), size = 1) + 
    scale_x_continuous("Observations",
                       #limits = c(min_x_value, max_x_value),
                       breaks = x_values,
                       labels = x_values) + 
    scale_y_continuous("Predictions", 
                       #limits = c(min_y_value, max_y_value), 
                       breaks = y_values,
                       labels = y_values) +
    geom_smooth(method = "lm", formula = y ~ x - 1, se = FALSE) + 
    coord_cartesian(xlim = c(min_x_value, max_x_value),
                    ylim = c(min_y_value, max_y_value)) + 
    #geom_text(aes(label = data_id), hjust = 0, vjust = 0) +
    geom_text(data = eq_df, aes(x = x_text, y = max_y_value, label = eq), parse = TRUE) +
    theme(axis.title.x = element_text(hjust = 0.5, vjust = 1, size = 15, margin = margin(t = 20)),
          axis.title.y = element_text(hjust = 0.5, vjust = 0, size = 15, margin = margin(r = 20)),
          axis.text.x = element_text(size = 11),
          axis.text.y = element_text(size = 11),
          plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))
  
  dir.create(file_path, FALSE, TRUE)
  
  png(filename = file.path(file_path, file_name), 
      width = 6, 
      height = 4, 
      units = "in", 
      res = 200)
  
  print(p)
  
  dev.off()
  
}
