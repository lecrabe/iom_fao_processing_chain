####################################################################################
####### Object:  Merge results from classification and assign change value
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/08                                          
####################################################################################

field_time <- Sys.time()

####################################################################################
### Read shapefile with subplots and AGB data per subplot
shp <- readOGR(plot_shp)
agb <- read.csv(agb_data)

####################################################################################
### Check data and set names
table(shp@data$plot,shp@data$subplot)
table(agb$plot_id)

names(agb)
agb <- agb[,c("plot_id","subplot_id","tree_id","tree_name","plot_radius","stump_height","tree_dia","tree_total_lgt","density","slope" )]

summary(agb)

summary(agb[agb$tree_dia <  30,]$plot_radius)
summary(agb[agb$tree_dia >= 30,]$plot_radius)

####################################################################################
### Identify if the record is a stump
agb$stump <- 0
agb[is.na(agb$tree_total_lgt),]$stump <- 1

####################################################################################
### Apply the CHAVE equation for the trees "AGB = 0.0673*(dbh^2*h*wd)^0.976"
agb$agb_tree <- 0.0673*(agb$tree_dia*agb$tree_dia*agb$tree_total_lgt*agb$density)^0.976

####################################################################################
### Apply cylinder equation for the stumps "AGB = pi *(dbh/2)^2 * h * wd / 1000"
agb[agb$stump ==1,]$agb_tree <- pi * (agb[agb$stump ==1,]$tree_dia/2)^2 *  agb[agb$stump ==1,]$stump_height / 100 * agb[agb$stump ==1,]$density / 1000

####################################################################################
### Apply expansion factor to the biomass
agb$agb_ha <- agb$agb_tree * 10000 / (agb$plot_radius*agb$plot_radius*pi*cos(atan((agb$slope/100))))

####################################################################################
### Compute Basal Area
agb$basal_ha <- pi*(agb$tree_dia/2)^2 / 10000 * 10000 / (agb$plot_radius*agb$plot_radius*pi*cos(atan((agb$slope/100))))

####################################################################################
### Create unique subplot ID for the AGB database
codes <- data.frame(cbind(1:5,c("c","n","e","s","w")))
names(codes) <- c("subplot_id","subplot_code")
agb <- merge(agb,codes)

agb$subplot_id <- paste0(agb$plot_id,agb$subplot_code)

head(agb)
####################################################################################
### Calculate AGB/ha, Basal area and Mean Slope per subplot
df_agb <- tapply(agb$agb_ha,  agb[,c("subplot_id")],FUN = sum)
df_bas <- tapply(agb$basal_ha,agb[,c("subplot_id")],FUN = sum)
df_slp <- tapply(agb$slope,   agb[,c("subplot_id")],FUN = mean)

df <- data.frame(cbind(df_agb,df_bas,df_slp))

names(df) <- c("plot_agb_ha","plot_basal","plot_slope")
df$subplot_id <- rownames(df)


####################################################################################
### Create unique subplot ID in the shapefile
shp@data$subplot_id <-paste0(shp@data$plot,shp@data$subplot)
shp@data$id <- row(shp@data)[,1]

####################################################################################
### Merge the AGB data per subplot into the shapefile
shp@data <- arrange(merge(shp@data,df,all.x=TRUE),id)[,c("id","plot","subplot","subplot_id","xcoord","ycoord","plot_agb_ha","plot_basal","plot_slope")]

####################################################################################
### Create a MODE function (majority rule extractor)
mode <- function(x){
  names(which.max(
    table(extract[x])
  ))
}

####################################################################################
### Merge the fuelwood change data into the shapefile
rast <- raster(paste0(comb_dir,"lc2015_change940316.tif"))
extract <- extract(x = rast,y = shp)
shp@data$class_lcc <- sapply(1:nrow(shp),mode)

####################################################################################
### Merge the land cover 2015 data into the shapefile
rast <- raster(train_input)
extract <- extract(x = rast,y = shp)
shp@data$class_lc <- sapply(1:nrow(shp),mode)

####################################################################################
dbf <- shp@data

####################################################################################
names(dbf) <- c("id","plot","subplot","subplot_id","xcoord","ycoord","plot_agb_ha","plot_basal","plot_slope","class_change","class_lc")

####################################################################################
### replace NO DATA of plots measured in the field by zero, no biomass for these points
dbf[is.na(dbf)] <- 0


####################################################################################
### Determine which classes of LC and Change fall within the measured plots
my_legend_lc     <- data.frame(cbind(legend[legend$value %in% unique(dbf$class_lc),]$value,
                                     legend[legend$value %in% unique(dbf$class_lc),]$class)
)

names(my_legend_lc) <- c("lc_code","lc_class")

my_legend_change <- data.frame(cbind(
  1:9,
  c("fuelwood","non_fuelwood","loss_recent","loss_old","gain_recent","gain_old","degradation","agriculture","water")
  )
  )

names(my_legend_change) <- c("chge_code","chge_class")

dbf1 <-  merge(dbf,my_legend_lc,by.x="class_lc",by.y="lc_code")
dbf1 <- merge(dbf1,my_legend_change,by.x="class_change","chge_code")
dbf1 <- arrange(dbf1,id)

write.csv(dbf1,paste0(rootdir,"subplot_agb_basal_20170421.csv"),row.names = F)

shp@data <- dbf1

### Export the DBF again
writeOGR(obj=shp,
         layer = "subplots_field_rs_data",
         dsn = paste0(field_dir,"subplots_field_rs_data.shp"),
         driver = "ESRI Shapefile",
         overwrite_layer = TRUE
)

####################################################################################
### Check how many plots were eventually measured in each crossed category
table(dbf1$lc_class,dbf1$chge_class)

### Compute AVERAGE and SD of AGB by land cover class and change class
lc_agb <- data.frame(cbind(tapply(dbf1$plot_agb_ha,
                                  dbf1[,c("lc_class","chge_class")],FUN = mean),
                           tapply(dbf1$plot_agb_ha,
                                  dbf1[,c("lc_class","chge_class")],FUN = sd)
)
)

names(lc_agb) <- paste0(c("agb_ha_mean","agb_ha_sd"),unique(my_legend_change$chge_class))
lc_agb$class <- rownames(lc_agb)
lc_agb

### Compute AVERAGE and SD of BASAL by land cover class and change class
lc_basal <- data.frame(cbind(tapply(dbf$plot_basal,
                                    dbf[,c("class_lc","class_change")],FUN = mean),
                             tapply(dbf$plot_basal,
                                    dbf[,c("class_lc","class_change")],FUN = sd)
))

names(lc_basal) <- c("basal_mean","basal_sd")
lc_basal$class <- rownames(lc_basal)
lc_basal

####################################################################################
### Create biomass map
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"lc2015_change940316.tif"),
               paste0(comb_dir,"tmp_lc2015_change940316_int16.tif")
))

system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"lc_map_clip.tif"),
               paste0(comb_dir,"tmp_lc_map_clip_int16.tif")
))


system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --type=UInt16 --outfile=%s --calc=\"%s\"",
               paste0(comb_dir,"tmp_lc2015_change940316_int16.tif"),
               paste0(comb_dir,"tmp_lc_map_clip_int16.tif"),
               paste0(comb_dir,"tmp.tif"),
               "(A*100)+B"
))

agb_all_trans <- read.csv(paste0(field_dir,"agb_ha_1994.csv"))

agb_all_trans[is.na(agb_all_trans)] <- 0

df <- expand.grid((1:9)*100,agb_all_trans$lc_classes)
df$code <- df$Var1+df$Var2
df <- arrange(df,code)

df$agb <- c(unlist(agb_all_trans$X1),
                unlist(agb_all_trans$X2),
                unlist(agb_all_trans$X3),
                unlist(agb_all_trans$X4),
                unlist(agb_all_trans$X5),
                unlist(agb_all_trans$X6),
                unlist(agb_all_trans$X7),
                unlist(agb_all_trans$X8),
                unlist(agb_all_trans$X9))
df$agbC <- df$agb*.47/1000


write.table(df,paste0(comb_dir,"reclass_agb.txt"),quote=FALSE, col.names=FALSE,row.names=FALSE)


system(sprintf("(echo %s; echo 1; echo 3; echo 5; echo 0) | oft-reclass -oi  %s %s",
               paste0(comb_dir,"reclass_agb.txt"),
               paste0(comb_dir,"tmp_reclass_agb.tif"),
               paste0(comb_dir,"tmp.tif")
))

system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(comb_dir,"lc2015_change940316.tif"),
               paste0(comb_dir,"tmp_reclass_agb.tif"),
               paste0(comb_dir,"tmp_reclass_agb_nd.tif"),
               "(A==0)*255+(A>0)*B"
))


colfunc <- colorRampPalette(c("white", "darkgreen"))

pct <- data.frame(cbind(
  c(0:ceiling(max(df$agbC)),255),
  c(colfunc(ceiling(max(df$agbC))+1),"#000000")
))

pct3 <- data.frame(cbind(pct$X1,col2rgb(pct$X2)[1,],col2rgb(pct$X2)[2,],col2rgb(pct$X2)[3,]))
write.table(pct3,paste0(comb_dir,"color_table_agb.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(comb_dir,"color_table_agb.txt"),
               paste0(comb_dir,"tmp_reclass_agb_nd.tif"),
               paste0(comb_dir,"tmp_reclass_pct_agb.tif")
))

################################################################################
## Compress
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"tmp_reclass_pct_agb.tif"),
               paste0(comb_dir,"agb_tC-ha_1994.tif")
))

system(sprintf("rm -r %s",
               paste0(comb_dir,"tmp*.tif")))

