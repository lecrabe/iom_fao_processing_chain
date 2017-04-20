####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/10/31                                          
####################################################################################

####################################################################################
#######          GLOBAL ENVIRONMENT VARIABLES
####################################################################################

rootdir <- "/home/dannunzio/Documents/iom_change_detection/"
setwd(rootdir)

dem_dir <- paste0(rootdir,"dem_bgd/")
img_dir <- paste0(rootdir,"satellite_images/")
input_dir <- paste0(rootdir,"input/")


###################################################################################
#######         Satellite IMAGERY
###################################################################################
img_2016 <- paste0(rootdir,"satellite_images/spot16_merge.tif")

img_2003 <- paste0(rootdir,"satellite_images/spot03.tif")
img_1994 <- paste0(rootdir,"satellite_images/spot_pan_xs.tif")
img_2015 <- paste0(rootdir,"satellite_images/spot15.tif")
img_2017 <- paste0(rootdir,"satellite_images/stnl17.tif")


###################################################################################
#######         Clip of AOI
###################################################################################

tile <- "aoi_bb_vhr"

clip_2003  <- paste0(rootdir,"input/",tile,"2003.tif")
clip_1994  <- paste0(rootdir,"input/",tile,"1994.tif")
clip_2015  <- paste0(rootdir,"input/",tile,"2015.tif")
clip_2017  <- paste0(rootdir,"input/",tile,"2017.tif")

#407391.837021 2355552.44838 427333.288348 2337913.60472  Clip 
#419858.749895 2318529.70746 423327.75324 2315060.70412   Hnila
#400124.373988 2350357.71835 426351.978035 2312943.23829  AOI BB

# system(sprintf("gdal_translate -projwin %s %s %s %s  -co COMPRESS=LZW -of GTiff %s  %s ",
#                400124.373988, #419858.749895, #407391.837021, #412402.134338,
#                2350357.71835, #2318529.70746, #2355552.44838, #2329376.36295,
#                426351.978035, #423327.75324 , #427333.288348, #422923.308776,
#                2312943.23829, # 2315060.70412, #2337913.60472, #2324917.69451,
#                img_2003,
#                clip_2003
# ))

extent <- extent(raster(img_2016))
res    <- res(raster(img_2016))

system(sprintf("gdalwarp -te %s %s %s %s -tr %s %s -co COMPRESS=LZW -overwrite -of GTiff %s  %s ",
               extent@xmin,
               extent@ymin,
               extent@xmax,
               extent@ymax,
               res[1],
               res[2],
               img_1994,
               clip_1994
))

system(sprintf("gdalwarp -te %s %s %s %s -tr %s %s -co COMPRESS=LZW -overwrite -of GTiff %s  %s ",
               extent@xmin,
               extent@ymin,
               extent@xmax,
               extent@ymax,
               res[1],
               res[2],
               img_2015,
               clip_2015
))

system(sprintf("gdalwarp -te %s %s %s %s -tr %s %s -co COMPRESS=LZW -overwrite -of GTiff %s  %s ",
               extent@xmin,
               extent@ymin,
               extent@xmax,
               extent@ymax,
               res[1],
               res[2],
               img_2017,
               clip_2017
))

system(sprintf("gdalwarp -te %s %s %s %s -tr %s %s -co COMPRESS=LZW -overwrite -of GTiff %s  %s ",
               extent@xmin,
               extent@ymin,
               extent@xmax,
               extent@ymax,
               res[1],
               res[2],
               img_2003,
               clip_2003
))


###################################################################################
#######         AOI and conversion to Byte
###################################################################################

tile <- "aoi_bb_vhr_byte"

clip_2003_byte  <- paste0(rootdir,"input/",tile,"2003.tif")
clip_1994_byte  <- paste0(rootdir,"input/",tile,"1994.tif")
clip_2015_byte  <- paste0(rootdir,"input/",tile,"2015.tif")
clip_2016_byte  <- paste0(rootdir,"input/",tile,"2016.tif")
clip_2017_byte  <- paste0(rootdir,"input/",tile,"2017.tif")


system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW -of GTiff %s  %s",
               clip_1994,
               clip_1994_byte
))

system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW -of GTiff %s  %s",
               clip_2003,
               clip_2003_byte
))

system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW -of GTiff %s  %s",
               clip_2015,
               clip_2015_byte
))

system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW -of GTiff %s  %s",
               img_2016,
               clip_2016_byte
))

system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW -of GTiff %s  %s",
               clip_2017,
               clip_2017_byte
))


nbands(raster(clip_2017_byte))
nbands(raster(clip_2016_byte))
nbands(raster(clip_2015_byte))
nbands(raster(clip_2003_byte))
nbands(raster(clip_1994_byte))


###################################################################################
#######          DEM
###################################################################################
# 
# dem_input <- paste0(dem_dir,"srtm_elev_30m_bgd.tif")
# slp_input <- paste0(dem_dir,"srtm_slope_30m_bgd.tif")
# asp_input <- paste0(dem_dir,"srtm_aspect_30m_bgd.tif")

# ###################################################################################
# #######          MERGE 30m SRTM tiles
# system(sprintf("gdal_merge.py -v -o %s %s %s",
#                paste0(dem_dir,"tmp.tif"),
#                paste0(dem_dir,"N20E092.hgt"),
#                paste0(dem_dir,"N21E092.hgt")
# ))
# 
# system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp.tif"),
#                dem_input
# ))
# 
# system(sprintf("rm %s",
#   paste0(dem_dir,"tmp.tif")
# ))
# 
# ###################################################################################
# #######          Compute slope
# system(sprintf("gdaldem slope -s 111120 -co COMPRESS=LZW %s %s",
#                dem_input,
#                paste0(dem_dir,"tmp.tif")
#                ))
# 
# system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp.tif"),
#                slp_input
# ))
# 
# system(sprintf("rm %s",
#                paste0(dem_dir,"tmp.tif")
# ))
# 
# ###################################################################################
# #######          Compute aspect
# system(sprintf("gdaldem aspect -co COMPRESS=LZW %s %s",
#                dem_input,
#                paste0(dem_dir,"tmp.tif")
# ))
# 
# system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp.tif"),
#                asp_input
# ))
# 
# system(sprintf("rm %s",
#                paste0(dem_dir,"tmp.tif")
# ))
# 

# ###################################################################################
# #######          Cloud mask rasterization

system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               paste0(cloud_dir,"cloud_spot_2016_utm.shp"),
               paste0(t1_dir,"aoi_bb_vhr_byte2016.tif"),
               paste0(cloud_dir,"cloud_spot_2016.tif"),
               "id"

))


