####################################################################################
####### Object:  generate training data polygons through unsupervised classification
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/10/31                                           
####################################################################################

training_start <- Sys.time()

################################################################################
## Compute min-max of imagery
system(sprintf("oft-mm -um %s %s > %s",im_input,im_input,paste0(outdir,"/","minmax.txt")))
system(sprintf("gdalinfo -stats %s > %s",im_input,paste0(outdir,"/","info.txt")))

nbands  <- nbands(raster(im_input))
mm_info <- readLines(paste0(outdir,"/","minmax.txt"))
info    <- readLines(paste0(outdir,"/","info.txt"))
stat_info <- data.frame(t(data.frame(strsplit(info[grep(info,pattern="Minimum=")],split=","))))

true_min <- as.numeric(unlist(strsplit(mm_info[grep(mm_info,pattern=" min =")],split=" = "))[2*(1:nbands)])
true_max <- as.numeric(unlist(strsplit(mm_info[grep(mm_info,pattern=" max =")],split=" = "))[2*(1:nbands)])
stat_max <- as.numeric(gsub(pattern = "Maximum=",replacement="",stat_info[,2]))
stat_mean<- as.numeric(gsub(pattern = "Mean=",replacement="",stat_info[,3]))
stat_sd  <- as.numeric(gsub(pattern = "StdDev=",replacement="",stat_info[,4]))

stats <- data.frame(cbind(true_min,true_max,stat_max,stat_mean,stat_sd) )
stats <- round(stats,digits=0)

stats

################################################################################
## Normalize each band as a percentage of its maximum statistics
################################################################################

## Create normalization equation
norm_eq <- paste0("echo ",nbands)

for(band in 1:nbands){
  bstat <- stats[band,]
  element <- paste0("echo \"#",band," ",bstat$stat_max," / 100 *\"")
  norm_eq <- paste0(norm_eq," ;",element)
}

norm_eq <- paste0("(",norm_eq,")")

## Apply  normalization equation
system(sprintf(
  "%s | oft-calc -ot Byte %s %s",
  norm_eq,
  im_input,
  paste0(outdir,"/","tmp_norm.tif")
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(outdir,"/","tmp_norm.tif"),norm_input))
system(sprintf(paste0("rm ",outdir,"/","tmp*.tif")))

################################################################################
## Compute the product of each normalized bands
################################################################################
prod_eq <- paste0("#1")

for(band in 2:nbands){
  bstat <- stats[band,]
  element <- paste0("#",band," * 0.5 ^")
  prod_eq <- paste0(prod_eq," ",element)
}

prod_eq <- paste0("(echo 1; echo \"",prod_eq,"\")")
prod_eq
system(sprintf(
  "%s | oft-calc -ot Byte %s %s",
  prod_eq,
  norm_input,
  paste0(outdir,"/","tmp_prod.tif")
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(outdir,"/","tmp_prod.tif"),prod_input))
system(sprintf(paste0("rm ",outdir,"/","tmp*.tif")))

################################################################################
## Clip the SLOPE of the DEM to the extent of the interest tile
################################################################################
system(sprintf("oft-clip.pl %s %s %s",
               im_input,
               slp_input,
               paste0(outdir,"tmp.tif")
               ))

system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"tmp.tif"),
               slp_clip))

system(sprintf("rm %s",
               paste0(outdir,"tmp.tif")))


################################################################################
## Create mask of water like aspect :  N / R * N / G < 1
################################################################################
NIR <- 1
RED <- 2
GRN <- 3

system(sprintf("(echo 1; echo \" %s %s / 1 < 0 %s %s / 1 < 0 1 ? ?\") | oft-calc %s %s",
               paste0("#",NIR),
               paste0("#",GRN),
               paste0("#",NIR),
               paste0("#",RED),
               im_input,
               paste0(outdir,"/","tmp_dark.tif")))

################################################################################
## Create mask of shadows by dark and slope
################################################################################
system(sprintf("gdal_calc.py -A %s -B %s -C %s --outfile=%s --calc=\"%s\"",
               paste0(outdir,"/","tmp_dark.tif"),
               slp_clip,
               prod_input,
               paste0(outdir,"/","tmp_shadow.tif"),
               paste0("A*(B>",th_wat,")*(C<12)"))
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_shadow.tif"),
               shd_msk))


################################################################################
## Create mask of water in not too high slopes
################################################################################
system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --calc=\"%s\"",
               paste0(outdir,"/","tmp_dark.tif"),
               slp_clip,
               paste0(outdir,"/","tmp_water.tif"),
               paste0("A*(B<",th_wat,")"))
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_water.tif"),
               wat_msk))
system(sprintf(paste0("rm ",outdir,"/","tmp*.tif")))




################################################################################
## Create non zero data mask from imagery
################################################################################


system(sprintf("(echo 1; echo \"#1 0 > 0 1 ? \") | oft-calc -ot Byte %s %s",
               im_input,paste0(outdir,"/","tmp_mask.tif")))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_mask.tif"),
               data_mask))

system(sprintf(paste0("rm ",outdir,"/","tmp*.tif")))



################################################################################
## Combine masks of water and shadow and good data to create a clear land mask
################################################################################
system(sprintf("gdal_calc.py -A %s -B %s -C %s --outfile=%s --calc=\"%s\"",
               wat_msk,
               shd_msk,
               data_mask,
               paste0(outdir,"/","tmp_clear_land.tif"),
               "C*(1-A)*(1-B)"
               )
)

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_clear_land.tif"),
               land_msk))

system(sprintf(paste0("rm ",outdir,"/","tmp*.tif")))


################################################################################
## Perform unsupervised classification
################################################################################
## Generate a systematic grid point
system(sprintf("oft-gengrid.bash %s %s %s %s",im_input,spacing_km,spacing_km,grid))

## Extract spectral signature
system(sprintf("(echo 2 ; echo 3) | oft-extr -o %s %s %s",sg_km,grid,im_input))

## Run k-means unsupervised classification
system(sprintf("(echo %s; echo %s) | oft-kmeans -o %s -i %s -um %s",
               sg_km,
               nb_clusters,
               paste0(outdir,"/","tmp_km_se.tif"),
               im_input,
               land_msk
               ))

## Sieve results with a 8 connected component rule
system(sprintf("gdal_sieve.py -8 %s %s",
               paste0(outdir,"/","tmp_km_se.tif"),
               paste0(outdir,"/","tmp_sieve_km_se.tif")
               ))
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_sieve_km_se.tif"),
               all_sg_km))
system(sprintf(paste0("rm ",outdir,"/","tmp_*.tif")))


################################################################################
## Clump the classification results : the IDs of the final classification zones 
################################################################################
system(sprintf("oft-clump -i %s -o %s -um %s",
               all_sg_km,
               paste0(outdir,"/","tmp_all_seg_id.tif"),
               all_sg_km))

system(sprintf("gdal_translate -ot Float32 -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_all_seg_id.tif"),
               all_sg_id))

system(sprintf(paste0("rm ",outdir,"/","tmp_*.*")))

################################################################################
## Get cluster class for each clump id
################################################################################
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",all_sg_km,all_sg_st,all_sg_id))

################################################################################
## Generate stats and select a sample of clusters
################################################################################

################################################################################
## Read the stats file and rename appropriately
df <- read.table(all_sg_st)
names(df) <- c("id","size","cluster")
classes <- levels(as.factor(df$cluster))

table(df$cluster)

################################################################################
## Select only the right size for the right rate
table(df[df$size > minsg_size,]$cluster)
table(df$cluster)

sel <- unlist(sapply(
  
  levels(as.factor(df[df$size > minsg_size,]$cluster)),
  function(x){
    if(table(df[df$cluster == x & df$size > minsg_size,]$cluster) < rate){df[df$cluster == x & df$size > minsg_size,]$id}else{
      sample(df[df$cluster == x & df$size > minsg_size,]$id,rate)
    }
      
      }))

df1 <- df[df$id %in% sel,]
table(df1$cluster)


########################################
## Generate a new cluster with zeros outside selection
df$newcluster <- df$cluster

df[!(df$id %in% sel ),]$newcluster<- 0


########################################
## Export the selected segments info as a table
write.table(df,sel_sg_st,quote=F,sep=" ",col.names = F,row.names = F)


########################################
## Reclass the selected polygons cluster
system(sprintf("(echo %s; echo 1; echo 1; echo 4; echo 0) | oft-reclass -oi %s %s",sel_sg_st,paste0(outdir,"/","tmp_reclass.tif"),all_sg_id))
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",paste0(outdir,"/","tmp_reclass.tif"),sel_sg_km))
system(sprintf(paste0("rm ",outdir,"/","tmp_reclass.tif")))

################################################################################
## Clump the selected segments to get unique IDs
system(sprintf("oft-clump -i %s -o %s -um %s",sel_sg_km,sel_sg_id,sel_sg_km))

################################################################################
## Clip the train product to the extent of the interest tile
system(sprintf("oft-clip.pl %s %s tmp.tif",
               im_input,
               train_input))

system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW tmp.tif %s",
               train_clip))
system(sprintf("rm tmp.tif"))

################################################################################
## Inject train  values inside the selected segments
system(sprintf("bash oft-segmode.bash %s  %s  %s ",
               sel_sg_id,
               train_clip,
               paste0(outdir,"/","tmp_sl_sg_train.tif")))

system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_sl_sg_train.tif"),
               sel_sg_train))

################################################################################
## Mask with the no_change mask
system(sprintf("gdal_calc.py -A %s -B %s -C %s --outfile=%s --calc=\"%s\"",
               sel_sg_train,
               noch_msk,
               slp_clip,
               paste0(outdir,"/","tmp_sl_sg_train_nochange.tif"),
               paste0("A*B*(C<",th_wat,")")
               ))

system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",paste0(outdir,"/","tmp_sl_sg_train_nochange.tif"),sel_sg_train))
system(sprintf(paste0("rm ",outdir,"/","tmp_*.tif")))

 
################################################################################
## Clump again the selected segments to get unique IDs including water & shadows
system(sprintf("oft-clump -i %s -o %s -um %s",
               sel_sg_train,
               paste0(outdir,"/","tmp_sel_seg_id.tif"),
               sel_sg_train))

system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(outdir,"/","tmp_sel_seg_id.tif"),
               sel_sg_id))

system(sprintf(paste0("rm ",outdir,"/","tmp_*.*")))

(training_time <- Sys.time() - training_start)


