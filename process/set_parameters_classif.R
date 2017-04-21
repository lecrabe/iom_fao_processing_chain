####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/10/31                                          
####################################################################################

####################################################################################
#######          BY PRODUCTS
####################################################################################
filename <- basename(im_input)
pathname <- dirname(im_input)
basename <- substr(filename,1,(nchar(filename)-4))

########################################
## OUTPUTS UNSUPERVISED CLASSIFICATION

norm_input<-paste0(outdir,"/",basename,"_normalized.tif")   # normalized version of the input
prod_input<-paste0(outdir,"/",basename,"_prodBands.tif")   # product of the normalized bands and square rooted


grid      <- paste0(outdir,"/",basename,"_grid.txt")   # grid point generated on the image
sg_km     <- paste0(outdir,"/",basename,"_sgkm.txt")   # spectral info on the grid point

all_sg_km <- paste0(outdir,"/",basename,"_alsgkm.tif") # cluster    of all segments (from k-means unsupervised classification)
all_sg_st <- paste0(outdir,"/",basename,"_alsgst.txt") # spectral   of all segments (stats of the k-means over the clump)
all_sg_id <- paste0(outdir,"/",basename,"_alsgid.tif") # identifier of all segments (clumped results of k-means)

sel_sg_km <- paste0(outdir,"/",basename,"_slsgkm.tif") # cluster    of selected segments 
sel_sg_st <- paste0(outdir,"/",basename,"_slsgst.txt") # spectral   of selected segments
sel_sg_id <- paste0(outdir,"/",basename,"_slsgid.tif") # identifier of selected segments 

########################################
## OUTPUTS MASKS

slp_clip  <- paste0(outdir,"/",basename,"_slope.tif")     # clip of SRTM derived slope over the tile
train_clip  <- paste0(outdir,"/",basename,"_train.tif")       # clip of train over the tile

wat_msk   <- paste0(outdir,"/",basename,"_water.tif")     # water mask
data_mask <- paste0(outdir,"/",basename,"_non_zero_data.tif") # good data mask
shd_msk   <- paste0(outdir,"/",basename,"_shadows.tif")   # shadow mask
land_msk  <- paste0(outdir,"/",basename,"_land.tif")   # land mask

train_wat  <- paste0(outdir,"/",basename,"_train_wat.tif")    # clip of train over the tile with water mask merged

sel_sg_train<- paste0(outdir,"/",basename,"_selsgtrain.tif")  # majority train class for each selected segment

########################################
## Output
img_sg_st <- paste0(outdir,"/",basename,"_imsgst.txt") # spectral of all segments (stats of the image over the clump)
img_tr_st <- paste0(outdir,"/",basename,"_imtrst.txt") # spectral of training (stats of the image over the training clump)
tra_tr_st <- paste0(outdir,"/",basename,"_trtrst.txt") # spectral of training (stats of the training values over the training clump)

img_clas  <- paste0(outdir,"/",basename,"_classif.txt") # results of classification as table
all_sg_rf <- paste0(outdir,"/",basename,"_rf.tif")      # results of classification as tif
output_rf <- paste0(outdir,"/",basename,"_output.tif")   # output of process

training  <- paste0(outdir,"/",basename,"_train.shp")  # polygonized selected segments

