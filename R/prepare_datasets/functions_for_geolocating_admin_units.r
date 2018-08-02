get_xy <- function(x){
  
  # geocode to find spatial coordinates using name of location
  
  country_name <- x$country
  # cat("country =", country_name, "\n")
  
  country_code <- x$ISO
  # cat("country code =", country_code, "\n")
  
  admin_level <- 1 
  
  location <- x$test_location
  # cat("location =", location, "\n")
  
  location_str <- ifelse(country_name != location, paste(location, country_name, sep = ", "), location)
  #cat("location string = ", location_str, "\n")
  
  geocode_run <- geocode(enc2utf8(location_str), output = "all") # take care of funny characters 
  
  if(geocode_run$status!="OK") {stop("no match!")}
  
  if(length(geocode_run$results)>1) {
    
    geocode_results <- get_geocode_results (geocode_run)
    
    viewport_areas <- apply(geocode_results, 1, calculate_viewport_area)
    
    result_match <- which(viewport_areas==max(viewport_areas))[1]
    
    location_xy <- geocode_results[result_match, c("lng","lat")]
    
    location_xy <- as.matrix(location_xy)
    
  } else {
    
    location_xy <- cbind(geocode_run$results[[1]]$geometry$location$lng,
                         geocode_run$results[[1]]$geometry$location$lat)
    
  }
  
  location_xy
  
}

get_admin_info <- function(x, info_names, shp_ls){
  
  # map overlay to find admin unit name using spatial coordinates
  
  country_code <- x$ISO
  # cat("country code =", country_code, "\n")
  
  shp <- shp_ls[[country_code]]

  overlay <- map_overlay(location_xy, shp)
  
  setNames(c(overlay[["ID_0"]],
             overlay[["ID_1"]]),
           info_names)
  
}

get_unique_iso <- function(x){
  unique(x$ISO)
}

load_shp <- function(x){
  
  admin_level <- 1 
  
  country_code <- x 
  shp_folder <- paste(country_code, "adm_shp", sep = "_")
  shp_name <- sprintf ("%s_adm%s", country_code, admin_level) 
  
  readOGR(file.path("data", "shapefiles", shp_folder), 
          shp_name,
          stringsAsFactors = FALSE,
          integer64 = "allow.loss")

}

map_overlay <- function(dat, shp){
  
  location_xy <- dat[, c("longitude", "latitude")]
  xy_spdf <- SpatialPoints(location_xy, proj4string = shp@proj4string)
  
  overlay <- sp::over(xy_spdf, shp)
  
  out_names <- c("ID_0", "ID_1", "name_0", "name_1")
  
  setNames(list(overlay$ID_0,
                overlay$ID_1,
                overlay$NAME_0,
                overlay$NAME_1), 
           out_names)
  
}

calculate_viewport_area <- function(x) {
  
  areaPolygon(rbind(c(x["point_1_x"], x["point_1_y"]),
                    c(x["point_2_x"], x["point_2_y"]),
                    c(x["point_3_x"], x["point_3_y"]),
                    c(x["point_4_x"], x["point_4_y"])))
  
}

get_geocode_results <- function(geocode_run){
  
  number_of_matches <- length(geocode_run$results)
  
  all_results <- data.frame(type=rep(0,number_of_matches,
                                     formatted_address=rep(0,number_of_matches), 
                                     lat=rep(0,number_of_matches), lng=rep(0,number_of_matches)))
  
  all_results$type <- sapply(geocode_run$results, function(x){x$types[[1]]})
  all_results$formatted_address <- sapply(geocode_run$results, function(x){x$formatted_address})
  all_results$lat <- sapply(geocode_run$results, function(x){x$geometry$location$lat})
  all_results$lng <- sapply(geocode_run$results, function(x){x$geometry$location$lng})
  
  all_results$point_1_x <- sapply(geocode_run$results, function(x){x$geometry$viewport$northeast$lng})
  all_results$point_1_y <- sapply(geocode_run$results, function(x){x$geometry$viewport$northeast$lat})
  all_results$point_2_x <- sapply(geocode_run$results, function(x){x$geometry$viewport$northeast$lng})
  all_results$point_2_y <- sapply(geocode_run$results, function(x){x$geometry$viewport$southwest$lat})
  all_results$point_3_x <- sapply(geocode_run$results, function(x){x$geometry$viewport$southwest$lng})
  all_results$point_3_y <- sapply(geocode_run$results, function(x){x$geometry$viewport$southwest$lat})
  all_results$point_4_x <- sapply(geocode_run$results, function(x){x$geometry$viewport$southwest$lng})
  all_results$point_4_y <- sapply(geocode_run$results, function(x){x$geometry$viewport$northeast$lat})
  
  all_results

}

subset_list_df <- function(x, fields){

  x[, fields]

}
