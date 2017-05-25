####################################################################################
####### Object:  Merge results from classification and assign change value
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/08                                          
####################################################################################

biomass_time <- Sys.time()

####################################################################################
### Translate into Int16 both LC map and Change map
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"lc2015_change940316.tif"),
               paste0(comb_dir,"tmp_lc2015_change940316_int16.tif")
))

system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"lc_map_clip.tif"),
               paste0(comb_dir,"tmp_lc_map_clip_int16.tif")
))

####################################################################################
### Combine both with a unique code: [1-9]*100 + lccode (2 digits)
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --type=UInt16 --outfile=%s --calc=\"%s\"",
               paste0(comb_dir,"tmp_lc2015_change940316_int16.tif"),
               paste0(comb_dir,"tmp_lc_map_clip_int16.tif"),
               paste0(comb_dir,"tmp.tif"),
               "(A*100)+B"
))

####################################################################################
### Read file with biomass coefficient in t/ha per class
agb_all_trans <- read.csv(paste0(field_dir,"agb_ha_1994.csv"))
#agb_all_trans <- read.csv(paste0(field_dir,"agb_ha_2016.csv"))
agb_all_trans[is.na(agb_all_trans)] <- 0

####################################################################################
### Create a unique code corresponding to each coefficient
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

df$agb_Tha <- df$agb/1000

####################################################################################
### Reclass the 2-code raster with the AGB code
write.table(df,paste0(comb_dir,"reclass_agb.txt"),quote=FALSE, col.names=FALSE,row.names=FALSE)

system(sprintf("(echo %s; echo 1; echo 3; echo 5; echo 0) | oft-reclass -oi  %s %s",
               paste0(comb_dir,"reclass_agb.txt"),
               paste0(comb_dir,"tmp_reclass_agb.tif"),
               paste0(comb_dir,"tmp.tif")
))

####################################################################################
### Give no data value of 9999
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(comb_dir,"lc2015_change940316.tif"),
               paste0(comb_dir,"tmp_reclass_agb.tif"),
               paste0(comb_dir,"tmp_reclass_agb_nd.tif"),
               "(A==0)*9999+(A>0)*B"
))

####################################################################################
### Create PCT
colfunc <- colorRampPalette(c("white", "brown"))

pct <- data.frame(cbind(
  c(0:ceiling(max(df$agb_Tha)),9999),
  c(colfunc(ceiling(max(df$agb_Tha))+1),"#000000")
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
               paste0(comb_dir,"agb_tdm-ha_1994.tif")
))

# system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
#                paste0(comb_dir,"tmp_reclass_pct_agb.tif"),
#                paste0(comb_dir,"agb_tdm-ha_2016.tif")
# ))

# system(sprintf("rm -r %s",
#                paste0(comb_dir,"tmp*.tif")))



