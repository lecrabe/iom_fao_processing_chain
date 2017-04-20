####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/04/20                                       
####################################################################################

scriptdir <- "/home/dannunzio/Documents/scripts/scripts_iom/"
setwd(scriptdir)

####################################################################################
#######          INPUTS
####################################################################################
source(paste0(scriptdir,"load_packages.R"),echo=TRUE)

####################################################################################
#######          CHANGE ACCORDINGLY TO PERIOD OF INTEREST
####################################################################################
time1       <- 2003
time2       <- 2016
t1_bands <- c(1,2,3) # NIR, RED, GREEN for SPOT 2,3,5
t2_bands <- c(4,1,2) # NIR, RED, GREEN for Spot 6 and 7

####################################################################################
#######          SET PARAMETERS
####################################################################################
source(paste0(scriptdir,"set_parameters_master.R"),echo=TRUE)
source(paste0(scriptdir,"set_parameters_imad.R"),echo=TRUE)
source(paste0(scriptdir,"set_parameters_merge.R"),echo=TRUE)


################################################################################
## Run the change detection
source(paste0(scriptdir,"change_detection_OTB.R"),echo=TRUE)


################################################################################
## Run the classification for time 1
outdir  <- paste0(tiledir,"/time1/")
dir.create(outdir)
im_input <- t1_input

        source(paste0(scriptdir,"set_parameters_classif.R"),echo=TRUE)

        source(paste0(scriptdir,"prepare_training_data.R"),echo=TRUE)
        source(paste0(scriptdir,"supervised_classification.R"),echo=TRUE)

################################################################################
## Run the classification for time 2
outdir  <- paste0(tiledir,"/time2/")
dir.create(outdir)
im_input <- t2_input

        source(paste0(scriptdir,"set_parameters_classif.R"),echo=TRUE)

        source(paste0(scriptdir,"prepare_training_data.R"),echo=TRUE)
        source(paste0(scriptdir,"supervised_classification.R"),echo=TRUE)


################################################################################
## Merge date 1 and date 2 (uncomment necessary script)
# source(paste0(scriptdir,"merge_datasets_9403.R"),echo=TRUE)
# source(paste0(scriptdir,"merge_datasets_0316.R"),echo=TRUE)

################################################################################
## After running for 2 periods, combine periods
# source(paste0(scriptdir,"combine_3_dates.R"),echo=TRUE)

################################################################################
## Call field data and inject into LCC map to generate statistics and biomass maps
# source(paste0(scriptdir,"inject_field_data.R"),echo=TRUE)





