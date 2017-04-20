####################################################################################
####### Object:  Run change detection between two dates             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/06                                           
####################################################################################
tile_start_time <- Sys.time()

####################################################################################################################
########### Normalize both inputs
####################################################################################################################
equ_1 <- paste0("(",paste0("echo ",nb_chdet_bands,";"),paste0("echo \"#\"",t1_bands,collapse = ";" ),")")
equ_2 <- paste0("(",paste0("echo ",nb_chdet_bands,";"),paste0("echo \"#\"",t2_bands,collapse = ";" ),")")


## Select the right bands of image 2 and mask with image 1
system(sprintf("%s | oft-calc -ot UInt16 -um %s %s %s",
               equ_2,
               t1_file,
               t2_file,
               paste0(imaddir,"tmp_t2.tif")))

## Select the right bands of image 1 and mask with image 2
system(sprintf("%s | oft-calc -ot UInt16 -um %s %s %s",
               equ_1,
               t2_file,
               t1_file,
               paste0(imaddir,"tmp_t1.tif")))

## Compress results
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(imaddir,"tmp_t1.tif"),
               t1_input
))

## Compress results
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(imaddir,"tmp_t2.tif"),
               t2_input
))


####################################################################################################################
########### Run change detection
###################################################################################################################

## Perform change detection
system(sprintf("otbcli_MultivariateAlterationDetector -in1 %s -in2 %s -out %s",
               t1_input,
               t2_input,
               paste0(imaddir,"tmp_chdet.tif")
               ))


## Multiply bands
system(sprintf("gdal_calc.py -A %s  --A_band 1 -B %s  --B_band 2  -C %s  --C_band 3  --outfile=%s --calc=\"%s\"",
               paste0(imaddir,"tmp_chdet.tif"),
               paste0(imaddir,"tmp_chdet.tif"),
               paste0(imaddir,"tmp_chdet.tif"),
               paste0(imaddir,"tmp_prod_chdet.tif"),
               paste0("A*B*C*1000")
)
)

## Compress results
system(sprintf("gdal_translate -ot Float32 -co COMPRESS=LZW -a_nodata none %s %s",
               paste0(imaddir,"tmp_prod_chdet.tif"),
               imad
))


################################################################################
## Create a no change mask
system(sprintf("gdal_calc.py -A %s  --outfile=%s --calc=\"%s\"",
               imad,
               paste0(imaddir,"tmp_noch.tif"),
               paste0("((A*A)<1000)")
)
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(imaddir,"tmp_noch.tif"),
               noch_msk))

system(sprintf("rm %s",
               paste0(imaddir,"*tmp*.*")
))

(time <- Sys.time() - tile_start_time)
