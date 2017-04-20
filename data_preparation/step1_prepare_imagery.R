####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/02/26                                       
####################################################################################
library(foreign)
library(plyr)
library(rgeos)
library(rgdal)
library(raster)
library(ggplot2)

options(stringsAsFactors = F)


rootdir <- "/media/dannunzio/hdd_remi/bangladesh_iom_imagery/"
workdir <- "/home/dannunzio/Documents/iom_change_detection/satellite_images/"

lsat94_dir <- paste0(rootdir,"tp_1994_landsat5/LT51360451993360ISP00/")
spot94_dir <- paste0(rootdir,"tp_1994_spot3/")
spot96_dir <- paste0(rootdir,"tp_1996_spot2/DATA_N657.17_E104.62/SPVIEW__2017_0/")
spot03_dir <- paste0(rootdir,"tp_2003_spot5/")
stnl16_dir <- paste0(rootdir,"tp_2016_sentinel2/")
stnl17_dir <- paste0(rootdir,"tp_2017_sentinel2/")

##########################################################################################
#### Merge the two SPOT 1994 tiles together
system(sprintf("gdal_merge.py -v -n 0 -co COMPRESS=LZW -o %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(spot94_dir,"*/SPVIEW*/IMAGERY.TIF")
               ))


#### Compress the resulting raster
system(sprintf("gdal_translate  -co COMPRESS=LZW -projwin 391388.692523 2355302.17198 431237.742841 2311208.03383 %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"spot94.tif")
))

#### Remove the temporary file
system(sprintf("rm -r %s",
               paste0(workdir,"tmp_merge.tif")
))

##########################################################################################
#### Clip the SPOT 1996 color data to the same extent
system(sprintf("oft-clip.pl %s %s %s",
               paste0(workdir,"spot94.tif"),
               paste0(spot96_dir,"IMAGERY.TIF"),
               paste0(workdir,"tmp_spot96.tif")
))


#### Compress the resulting raster
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_spot96.tif"),
               paste0(workdir,"spot96.tif")
))

#### Remove the temporary file
system(sprintf("rm -r %s",
               paste0(workdir,"tmp_spot96.tif")
))

##########################################################################################
#### Pansharpen SPOT 94 with spot 96 data
system(sprintf("otbcli_Pansharpening -inp %s -inxs %s -out %s %s",
               paste0(workdir,"spot94.tif"),
               paste0(workdir,"spot96.tif"),
               paste0(workdir,"tmp_spot_pan_xs.tif"),
               "uint16"
))

#### Compress the resulting raster
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_spot_pan_xs.tif"),
               paste0(workdir,"spot_pan_xs.tif")
))

#### Remove the temporary file
system(sprintf("rm -r %s",
               paste0(workdir,"tmp_spot_pan_xs.tif")
))

##########################################################################################
#### Cutdown SPOT3 imagery
system(sprintf("i=0;for file in %s;do i=$i+1;gdal_translate  -co COMPRESS=LZW -projwin 391388.692523 2355302.17198 431237.742841 2311208.03383 %s %s;done",
               paste0(spot03_dir,"*/*/SPVIEW*/IMAGERY.TIF"),
               "$file",
               paste0(workdir,"tmp_file_spot","$i",".tif")
               ))



#### Merge the four SPOT 2003 tiles together
system(sprintf("gdal_merge.py -v -n 0 -co COMPRESS=LZW -o %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"tmp_file_spot*.tif")
))


#### Compress the resulting raster
system(sprintf("gdal_translate  -co COMPRESS=LZW -projwin 391388.692523 2355302.17198 431237.742841 2311208.03383 %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"spot03.tif")
))

#### Remove the temporary files
system(sprintf("rm -r %s",
               paste0(workdir,"tmp_*.tif")
))

##########################################################################################
#### Merge the green, red and NIR bands of Sentinel 2 - 2016
system(sprintf("gdal_merge.py -v -separate -o %s %s",
               paste0(stnl16_dir,"tmp.tif"),
               paste0(stnl16_dir,"B0[3,4,8]*DJ.jp2")
               ))

#### Compress the resulting raster
system(sprintf("gdal_translate  -co COMPRESS=LZW %s %s",
               paste0(stnl16_dir,"tmp.tif"),
               paste0(stnl16_dir,"s2_20160208.tif")
))

#### Remove the temporary files
system(sprintf("rm -r %s",
               paste0(stnl16_dir,"tmp.tif")
))

system(sprintf("gdal_translate  -co COMPRESS=LZW -projwin 391388.692523 2355302.16198 431237.742841 2311208.03383 %s %s",
               paste0(stnl16_dir,"s2*.tif"),
               paste0(workdir,"stnl16.tif")
))


##########################################################################################
#### Merge the green, red and NIR bands of Sentinel 2 - 2017
system(sprintf("gdal_merge.py -v -separate -o %s %s",
               paste0(stnl17_dir,"tmp.tif"),
               paste0(stnl17_dir,"B0[3,4,8]*DJ.jp2")
))

#### Compress the resulting raster
system(sprintf("gdal_translate  -co COMPRESS=LZW %s %s",
               paste0(stnl17_dir,"tmp.tif"),
               paste0(stnl17_dir,"s2_20170208.tif")
))

#### Remove the temporary files
system(sprintf("rm -r %s",
               paste0(stnl17_dir,"tmp.tif")
))

system(sprintf("gdal_translate  -co COMPRESS=LZW -projwin 391388.692523 2355302.17198 431237.742841 2311208.03383 %s %s",
               paste0(stnl17_dir,"s2*.tif"),
               paste0(workdir,"stnl17.tif")
))


##########################################################################################
#### Calibrate histograms for 2016 SPOT data of different dates and adjust

source(paste0(scriptdir,"histogram_match.R"),echo=TRUE)

####### Merge tile 1 with the hybrid with histogram normalized

system(sprintf("gdal_merge.py -o %s -v -n 0 -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"spot16_norm.tif"),
               paste0(workdir,"spot16_1.tif")
))

####### Compress and delete temporary files
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"spot16_merge.tif")
))

system(sprintf("rm -r %s",
               paste0(workdir,"tmp*.tif")
))