####################################################################################
####### Object:  Run change detection between two dates             
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/06                                           
####################################################################################
tile_start_time <- Sys.time()

imaddir_tp1 <- paste0(result_dir,tile,"_1994_2003/imad/") 
imaddir_tp2 <- paste0(result_dir,tile,"_2003_2016/imad/") 

## Multiply bands
system(sprintf("gdal_calc.py -A %s  -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(imaddir_tp1,"tile_aoi_bb_vhr_byte_no_change_mask.tif"),
               paste0(imaddir_tp2,"tile_aoi_bb_vhr_byte_no_change_mask.tif"),
               paste0(comb_dir,"tile_aoi_bb_vhr_byte_no_change_mask_940316.tif"),
               paste0("A*B")
)
)

(time <- Sys.time() - tile_start_time)
