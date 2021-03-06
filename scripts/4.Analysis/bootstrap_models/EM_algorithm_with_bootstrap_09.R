# Extract partial dependence information and 
# make partial dependence plots

options(didehpc.cluster = "fi--didemrchnb")

my_resources <- c(
  file.path("R", "random_forest", "partial_dependence_plots_pdp.R"),
  file.path("R", "utility_functions.R"))

my_pkgs <- c("ggplot2")

context::context_log_start()
ctx <- context::context_save(path = "context",
                             sources = my_resources,
                             packages = my_pkgs)

context::context_load(ctx)
#context::parallel_cluster_start(8, ctx)


# define parameters ----------------------------------------------------------- 


parameters <- list(
  id = 24,
  shape_1 = 0,
  shape_2 = 5,
  shape_3 = 1e6,
  all_wgt = 1,
  dependent_variable = "R0_3",
  pseudoAbs_value = 0.5,
  grid_size = 5,
  no_predictors = 26,
  resample_grid_size = 20,
  foi_offset = 0.03,
  no_trees = 500,
  min_node_size = 20,
  no_samples = 200,
  EM_iter = 10) 

year.i <- 2007
year.f <- 2014
ppyear <- 64


# define variables ------------------------------------------------------------


model_type <- paste0("model_", parameters$id)

pdp_pt <- file.path("output",
                    "EM_algorithm",
                    "bootstrap_models",
                    model_type,
                    "partial_dependence")

v_imp_pt <- file.path("output",
                      "EM_algorithm",
                      "bootstrap_models",
                      model_type,
                      "variable_importance")

out_pt <- file.path("figures",
                    "EM_algorithm",
                    "bootstrap_models",
                    model_type)
  
  
# load data -------------------------------------------------------------------


predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection",
                                     "stepwise",
                                     "predictor_rank.csv"),
                           stringsAsFactors = FALSE)


# pre processing -------------------------------------------------------------- 


variables <- predictor_rank$name[1:parameters$no_predictors]

pd_table_fls <- list.files(pdp_pt, 
                           pattern = ".",
                           full.names = TRUE)

vi_table_fls <- list.files(v_imp_pt,
                           pattern = ".",
                           full.names = TRUE) 

pd_tables <- loop(pd_table_fls, readRDS, parallel = FALSE)

vi_tables <- loop(vi_table_fls, readRDS, parallel = FALSE)


# exctract --------------------------------------------------------------------


final_pd_df_ls <- lapply(seq_along(variables), extract_pd, variables, pd_tables)

final_pd_df <- do.call("rbind", final_pd_df_ls)
  

# rescale x axes --------------------------------------------------------------


final_pd_df_splt <- split(final_pd_df$x, final_pd_df$var)

for (i in seq_along(final_pd_df_splt)){
  
  one_set <- final_pd_df_splt[i]
  
  var <- names(one_set)
  
  scale <- 1
  
  if(grepl("Re.", var) | grepl("Im.", var)){
    
    scale <- ppyear * (year.f - year.i + 1) / 2 
    
  } 
  
  if(grepl("const_term$", var)){
    
    scale <- ppyear * (year.f - year.i + 1) 
    
  }  
  
  message(scale)
  
  final_pd_df_splt[[i]] <- one_set[[var]] / scale
  
}

final_pd_df$x <- unname(unlist(final_pd_df_splt))


# sort by var importance ------------------------------------------------------


vi_tables_norm <- lapply(vi_tables, normalize_impurity)

all_vi_values <- lapply(seq_along(variables), extract_vi, variables, vi_tables_norm)
  
importance <- vapply(all_vi_values, mean, numeric(1))  
  
vi_df <- data.frame(var = variables, importance = importance)

final_vi_df <- vi_df[order(vi_df$importance, decreasing = TRUE),]

final_pd_df$var <- factor(final_pd_df$var, 
                          levels = as.character(final_vi_df$var))
  

# plot ------------------------------------------------------------------------


# create new name strips for facet plots
new_names <- sprintf("%s (%s)", 
                     final_vi_df$var, 
                     paste0(round(final_vi_df$importance, 2),"%"))

x_name_strips <- setNames(new_names, final_vi_df$var)

dir.create(out_pt, FALSE, TRUE)

png(file.path(out_pt, "partial_dependence_plots.png"),
    width = 16.5,
    height = 18.5,
    units = "cm",
    pointsize = 12,
    res = 300)

p <- ggplot(final_pd_df, aes(x, q50)) +
  facet_wrap(facets = ~ var, 
             ncol = 4,
             scales = "free_x", 
             labeller = as_labeller(x_name_strips)) +
  geom_ribbon(data = final_pd_df, 
              mapping = aes(ymin = q05, ymax = q95), 
              fill = "gray80", 
              alpha = 0.5) +
  geom_line() +
  theme_bw(base_size = 11, base_family = "") +
  theme(plot.margin = unit(c(0.2, 0.2, 0.2, 0.2), "cm"))+
  labs(x = "Value of predictor",
       y = "Response (and 95% CI)",
       title = NULL) +
  theme(strip.text.x = element_text(size = 6),
        axis.text.x = element_text(size = 7))

print(p)

dev.off()
