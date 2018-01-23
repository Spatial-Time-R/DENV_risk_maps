# Combines the foi estimates from different studies / sources  into a single data frame

# install dev version of ggmap
devtools::install_github("dkahle/ggmap")

# load packages
library(ggmap) # for geocode()
library(maptools)


# ===================================================================
#
# 
# GET a key for the google map API geocoding tool 
# Do enable the google map geocoding tool on your google developer project page
# https://console.cloud.google.com/home/dashboard?project=dengue-mapping
# 
#
# ===================================================================


# load functions 
source(file.path("R", "prepare_datasets", "functions_for_geolocating_admin_units.r"))
source(file.path("R", "utility_functions.r"))


# ---------------------------------------- define parameters 


my_api_key <- "AIzaSyBuHLASHGLaorGdZidB5sNa-9C2fxXYj1c"

datasets <- c("NonSerotypeSpecificDatasets",
              "SerotypeSpecificDatasets",
              "additional serology",
              "additional_India_sero_data_Garg",
              "additional_India_sero_data_Shah",
              "All_caseReport_datasets")  

fields <- c("type", "ID_0", "ISO",
            "country", "ID_1", "adm1",
            "FOI", "variance", "latitude",
            "longitude", "reference", "date")

foi_out_pt <- file.path("output", "foi")
foi_out_nm <- "All_FOI_estimates_linear.txt"

deng_count_pt <- file.path("output", "datasets") 
deng_count_nm <- "dengue_point_countries.csv"


# ---------------------------------------- register your api key


register_google(key = my_api_key, account_type = "premium", day_limit = 100000)


# ---------------------------------------- pre processing


output_dts <- vector("list", length = length(datasets))

dts_names <- sapply(datasets, function(x) paste(x, "csv", sep = "."), USE.NAMES = FALSE)

dts_paths <- sapply(dts_names, function(x) file.path("data", "foi", x), USE.NAMES = FALSE)


# ---------------------------------------- load data


all_dts <- lapply(dts_paths, read.csv, header = TRUE, sep = ",", stringsAsFactors = FALSE)


# ---------------------------------------- run 


for (i in 1:length(datasets)){

  one_dts <- all_dts[[i]]  
  
  # Add `type` field
  if(i == length(datasets)){
    
    one_dts$type <- "caseReport"
    
  }else{
    
    one_dts$type <- "serology"
    
  }
  
  # convert dfs to lists 
  one_dts_ls <- df_to_list(one_dts, use_names = TRUE)  
  
  # get shp file info
  shp_info <- sapply(one_dts_ls, get_admin_name, country_code_fld = "ISO")  
  
  # attach to main datasets 
  one_dts$latitude <- shp_info[3,]
  one_dts$longitude <- shp_info[2,]
  one_dts$adm1 <- shp_info[1,]
  one_dts$ID_0 <- shp_info[4,]
  one_dts$ID_1 <- shp_info[5,]
  
  output_dts[[i]] <- one_dts
  
}

# subset
output_dts_2 <- lapply(output_dts, function(x) x[, fields])

# bind all together 
All_FOI_estimates <- do.call("rbind", output_dts_2)

# remove missing data 
All_FOI_estimates <- subset(All_FOI_estimates, !is.na(FOI))
  
# remove outliers 
All_FOI_estimates <- subset(All_FOI_estimates, ISO != "PYF" & ISO != "HTI")

dengue_point_countries <- All_FOI_estimates[!duplicated(All_FOI_estimates[, c("country", "ID_0")]), c("country", "ID_0")]


# ---------------------------------------- save 


write.table(All_FOI_estimates, 
            file.path(foi_out_pt, foi_out_nm), 
            row.names = FALSE, 
            sep = ",")

write.csv(dengue_point_countries[order(as.character(dengue_point_countries$country)), ], 
          file.path(deng_count_pt, deng_count_nm), 
          row.names = FALSE)


# # ---------------------------------------- Calculate FOI^2  
# 
# 
# All_FOI_estimates$FOI <- All_FOI_estimates$FOI^2
# 
# write.table(All_FOI_estimates, 
#             file.path("data", "foi", "All_FOI_estimates_squared.csv"), row.names = FALSE, sep = ",")
# 
# 
# #--------------------------------------------------------------------------------------------------------------
# # Calculate mean and se of FOI on the log scale, 
# # by assuming that FOI on the linear scale is lognormally distributed
# 
# get.mean.logscale <- function(mean_lognormal, var_lognormal)
# {
#   log(mean_lognormal^2 / sqrt(var_lognormal + mean_lognormal^2))  
# }  
#   
# get.var.logscale <- function(mean_lognormal, var_lognormal)
# {
#   log(1 + (var_lognormal / mean_lognormal^2))  
# }  
# 
# NonSerotypeSpecific_datasets_adm_names$FOI_logscale <- get.mean.logscale(NonSerotypeSpecific_datasets_adm_names$FOI, 
#                                                                          NonSerotypeSpecific_datasets_adm_names$variance)
# 
# NonSerotypeSpecific_datasets_adm_names$var_logscale <- get.var.logscale(NonSerotypeSpecific_datasets_adm_names$FOI, 
#                                                                         NonSerotypeSpecific_datasets_adm_names$variance)
# 
# SerotypeSpecific_datasets_adm_names$FOI_logscale <- get.mean.logscale(SerotypeSpecific_datasets_adm_names$FOI,
#                                                                       SerotypeSpecific_datasets_adm_names$variance)
# 
# SerotypeSpecific_datasets_adm_names$var_logscale <- get.var.logscale(SerotypeSpecific_datasets_adm_names$FOI,
#                                                                      SerotypeSpecific_datasets_adm_names$variance)
# 
# additional_serology_datasets_adm_names$FOI_logscale <- get.mean.logscale(additional_serology_datasets_adm_names$FOI,
#                                                                          additional_serology_datasets_adm_names$variance)
# 
# additional_serology_datasets_adm_names$var_logscale <- get.var.logscale(additional_serology_datasets_adm_names$FOI,
#                                                                         additional_serology_datasets_adm_names$variance)
# 
# caseReport_datasets_adm_names$FOI_logscale <- log(caseReport_datasets_adm_names$FOI)
# 
# All_FOI_estimates_log_scale <- rbind(NonSerotypeSpecific_datasets_adm_names[, c("type","country","country_code","adm1","latitude","longitude","FOI_logscale","var_logscale")],
#                                      SerotypeSpecific_datasets_adm_names[, c("type","country","country_code","adm1","latitude","longitude","FOI_logscale","var_logscale")],
#                                      additional_serology_datasets_adm_names[, c("type","country","country_code","adm1","latitude","longitude","FOI_logscale","var_logscale")],
#                                      caseReport_datasets_adm_names[, c("type","country","country_code","adm1","latitude","longitude","FOI_logscale","var_logscale")])
# 
# names(All_FOI_estimates_log_scale)[7:8] <- c("FOI", "variance")
# 
# write.table(All_FOI_estimates_log_scale, 
#             file.path("data", "foi", "All_FOI_estimates_log_scale.csv"), row.names=FALSE, sep=",")
# 
# # Check density plot of variance on linear and log scale 
# plot(density(x = All_FOI_estimates$variance, na.rm = TRUE))
# plot(density(x = All_FOI_estimates_log_scale$variance, na.rm = TRUE))
# 
# tiff("histogram_of_variance_linear_scale.tiff")
# print(hist(All_FOI_estimates$variance, breaks=1000, main = "linear scale"))
# dev.off()
# 
# tiff("histogram_of_variance_log_scale.tiff")
# print(hist(All_FOI_estimates_log_scale$variance, breaks=1000, main = "log scale"))
# dev.off()
# 
# 
# #--------------------------------------------------------------------------------------------------------------
# # Calculate logit(FOI)  
# 
# All_FOI_estimates$FOI <- logit(All_FOI_estimates$FOI)
# 
# write.table(All_FOI_estimates, 
#             file.path("data", "foi", "All_FOI_estimates_logit_scale.csv"), row.names=FALSE, sep=",")
# 
# #--------------------------------------------------------------------------------------------------------------
# # Calculate 1/FOI  
# 
# All_FOI_estimates$FOI <- 1 / All_FOI_estimates$FOI
# 
# write.table(All_FOI_estimates, 
#             file.path("data", "foi", "All_FOI_estimates_inverse.csv"), row.names = FALSE, sep = ",")