quick_polygon_map <- function(adm_shp_fl, 
                              country, 
                              y_var, 
                              out_pt, 
                              out_name){
  
  dir.create(out_pt, FALSE, TRUE)
  
  png(file.path(out_pt, out_name), 
      width = 18, 
      height = 8, 
      units = "cm",
      pointsize = 12,
      res = 300)

  my_col <- matlab.like(100)
  
  # country_list <- list("sp.polygons",
  #                      country,
  #                      col = NA,
  #                      fill = my_col[1],
  #                      first = TRUE)
  
  theme.novpadding <-list(layout.heights =
                            list(top.padding = 0,
                                 main.key.padding = 0,
                                 key.axis.padding = 0,
                                 axis.xlab.padding = 0,
                                 xlab.key.padding = 0,
                                 key.sub.padding = 0,
                                 bottom.padding = 0),
                          layout.widths =
                            list(left.padding = 0,
                                 key.ylab.padding = 0,
                                 ylab.axis.padding = 0,
                                 axis.key.padding = 0,
                                 right.padding = 0),
                          axis.line = 
                            list(col = "transparent"))
  
  #browser()
  
  adm_shp_fl@data[is.na(adm_shp_fl@data[, y_var]), y_var] <- 0
  
  max_y <- max(adm_shp_fl@data[, y_var], na.rm = T)
    
  p <- spplot(adm_shp_fl, 
              y_var, 
              at = seq(0, max_y, length.out = 100),
              col = NA,
              scales = list(x = list(draw = FALSE, 
                                     at = seq(-150, 150, 50)), 
                            y = list(draw = FALSE,
                                     at = seq(-60, 60, 20))),
              xlim = c(-180, 180),
              ylim = c(-60, 90),
              col.regions = my_col,
              colorkey = list(space = "right", height = 0.4),
              par.settings = theme.novpadding)#,
              #sp.layout = list(country_list))
  
  key <- draw.colorkey(p$legend[[1]]$args$key)
  
  p$legend <- NULL
  
  key$framevp$x <- unit(0.10, "npc")
  key$framevp$y <- unit(0.23, "npc")
  
  print(p)
  
  grid.draw(key)
  
  #grid.text("title", y = 0.40, x = 0.18, gp = gpar(fontsize = 8))
  
  dev.off()
  
}