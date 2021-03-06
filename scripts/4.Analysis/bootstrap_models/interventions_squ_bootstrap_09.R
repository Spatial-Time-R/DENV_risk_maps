# Plot proportional reduction in infections, cases and hospitalized cases 
# for an intervention with a general blocking effect on R0 

library(dplyr)
library(ggplot2)
library(RColorBrewer)


# define parameters -----------------------------------------------------------


sf_vals <- seq(0.9, 0.1, -0.1)

leg_titles <- c(expression('R'['0']*' reduction'), "Screening age")

burden_measures <- c("infections", "cases", "hosp") 

y_axis_titles <- c("Reduction in infections", "Reduction in cases", "Reduction in hopsitalized cases")

out_fig_path <- file.path("figures", 
                          "predictions_world", 
                          "bootstrap_models",
                          "general_intervention")

interventions <- "wolbachia"


# define variables ------------------------------------------------------------


sf_vals_perc <- (1 - sf_vals) * 100

leg_labels <- list(paste0(sf_vals_perc, "%"), c("9", "16"))

my_col <- brewer.pal(9, "YlGnBu")


# plotting --------------------------------------------------------------------


for (i in seq_along(interventions)) {
  
  for (j in seq_along(burden_measures)) {
    
    my_var_name <- burden_measures[j]
    
    intervention_name <- interventions[i]
    
    y_axis_title <- y_axis_titles[j]
    
    summary_table_orig <- read.csv(file.path("output", 
                                             "predictions_world", 
                                             "bootstrap_models",
                                             paste0("prop_change_", my_var_name, "_", intervention_name, ".csv")),
                                   header = TRUE)
    
    if(intervention_name == "wolbachia"){
      
      summary_table <- subset(summary_table_orig, treatment != 1 & phi_set_id != "FOI")
      summary_table$treatment <- factor(summary_table$treatment, levels = sf_vals)
      
    } else {
      
      summary_table <- summary_table_orig
      summary_table$treatment <- as.factor(summary_table$treatment)
      
    }
    
    y_values <- seq(0, 1, 0.2)
    
    p <- ggplot(summary_table, aes(x = treatment, y = mean, fill = treatment, ymin = lCI, ymax = uCI)) +
      geom_bar(stat = "identity", position = "dodge", width = 1) +
      geom_errorbar(width = .25, position = position_dodge(.9)) +
      facet_grid(. ~ phi_set_id) +
      scale_fill_manual(values = my_col,
                        labels = leg_labels[[i]],
                        guide = guide_legend(title = leg_titles[i],
                                             keywidth = 1,
                                             keyheight = 1)) +
      xlab(NULL) +
      scale_y_continuous(y_axis_title,
                         breaks = y_values,
                         labels = paste0(y_values * 100, "%"),
                         limits = c(min(y_values), max(y_values)),
                         expand = expand_scale(mult = c(0, .05))) +
      theme_bw() +
      theme(axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            axis.text.y = element_text(size = 12),
            plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
            strip.text.x = element_text(size = 8))
    
    dir.create(out_fig_path, FALSE, TRUE)
    
    barplot_fl_nm <- paste0("proportional_reduction_in_", my_var_name, "_", intervention_name, ".png")
    
    png(file.path(out_fig_path, barplot_fl_nm),
        width = 17,
        height = 9,
        units = "cm",
        pointsize = 12,
        res = 300)
    
    print(p)
    
    dev.off()
    
  }
  
}
