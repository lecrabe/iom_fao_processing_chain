####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/10/31                                          
####################################################################################

####################################################################################
#######          GLOBAL ENVIRONMENT VARIABLES
####################################################################################
options(stringsAsFactors=FALSE)

rootdir <- "/home/dannunzio/Documents/iom_change_detection/"

t1_dir    <- paste0(rootdir,"input/")
t2_dir    <- paste0(rootdir,"input/")

tile <- "aoi_bb_vhr_byte"

training_dir <- paste0(rootdir,"lcmap_2015/")
dem_dir      <- paste0(rootdir,"dem_bgd/")
result_dir   <- paste0(rootdir,"results/")
cloud_dir    <- paste0(rootdir,"cloud_mask/")
field_dir    <- paste0(rootdir,"field_data/")
comb_dir     <- paste0(result_dir,"aoi_bb_vhr_combined_1994_2003_2016/")

dem_input    <- paste0(dem_dir,"srtm_elev_30m_bgd.tif")
slp_input    <- paste0(dem_dir,"srtm_slope_30m_bgd.tif")
asp_input    <- paste0(dem_dir,"srtm_aspect_30m_bgd.tif")

train_input  <- paste0(training_dir,"lc_map_20170410.tif")

plot_shp     <- paste0(field_dir,"subplot_buffe_19m.shp")
agb_data     <- paste0(field_dir,"data_biomass_20170412.csv")

####################################################################################
#######          PARAMETERS
####################################################################################


spacing_km  <- 50   # UTM in meters, Point spacing in grid for unsupervised classification
th_shd      <- 30   # in degrees (higher than threshold and dark is mountain shadow)
th_wat      <- 15   # in degrees (lower than threshold is water)
rate        <- 100  # Define the sampling rate (how many objects per cluster)
minsg_size  <- 10   # Minimum segment size in numbers of pixels

thresh_imad <-10000 # acceptable threshold for no_change mask from IMAD
thresh_gfc  <- 70   # tree cover threshold from GFC to define forests

nb_chdet_bands <- 3 # Number of common bands between imagery for change detection

nb_clusters <- 50   # Number of clusters in the KMEANS classification

train_wat_class <- 5  # class for water
train_shd_class <- 0  # class for shadows

####################################################################################
#######          TRAINING DATA LEGEND
####################################################################################
legend <- read.table(paste0(training_dir,"legend.txt"))
names(legend) <- c("item","alpha","value","class","color")

legend$class <- gsub("label=","",x = legend$class)
legend$class <- gsub("\"","",x = legend$class)

legend$value <- gsub("value=","",x = legend$value)
legend$value <- gsub("\"","",x = legend$value)

legend <- legend[,3:4]

nbclass <- nrow(legend)

legend$value <- as.numeric(legend$value)
