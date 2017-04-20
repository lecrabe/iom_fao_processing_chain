####################################################################################
####### Object:  Merge results from classification and assign change value
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/08                                          
####################################################################################

merge_time <- Sys.time()

################################################################################
## Clump the results of the time 2 classification
system(sprintf("oft-clump -i %s -o %s -um %s",
               t2_file,
               paste0(mergedir,"/","tmp_sel_seg_id.tif"),
               t2_file
               ))

system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(mergedir,"/","tmp_sel_seg_id.tif"),
               segs_id
               ))

system(sprintf(paste0("rm ",mergedir,"/","tmp_*.*")))

################################################################################
## Compute time 2 classification value on each segment
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               t2_file,
               t2_cl_st,
               segs_id))

################################################################################
## Compute time 1 classification distribution on each segment
system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
               t1_file,
               t1_cl_st,
               segs_id,
               nbclass
               ))

################################################################################
## Compute IMAD change values on each segment
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               imad,
               im_cl_st,
               segs_id))

################################################################################
## Compute cloud value on each segment
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               paste0(cloud_dir,"cloud_spot_2016.tif"),
               paste0(cloud_dir,"cloud_spot_2016.txt"),
               segs_id))



################################################################################
## Create one data file with all info
df_t2 <- read.table(t2_cl_st)
df_t1 <- read.table(t1_cl_st)
df_im <- read.table(im_cl_st)
df_cl <- read.table(paste0(cloud_dir,"cloud_spot_2016.txt"))

names(df_t2) <- c("sg_id","sg_sz","t2_class")
names(df_im) <- c("sg_id","sg_sz","imad")
names(df_t1) <- c("sg_id","total","no_data",legend$class)
names(df_cl) <- c("sg_id","sg_sz","cloud16")

head(df_t2)
head(df_t1)
head(df_im)

summary(df_t1$total - rowSums(df_t1[,3:ncol(df_t1)]))

df <- df_t2

df$sortid <- row(df)[,1]

df <- merge(df,df_im,by.x="sg_id",by.y="sg_id")
df <- merge(df,df_t1,by.x="sg_id",by.y="sg_id")
df <- merge(df,df_cl,by.x="sg_id",by.y="sg_id")

df <- merge(df,legend,by.x="t2_class",by.y="value")

################################################################################
## Determine criterias for change 

## Take out the columns that don't have any pixels coded
df1 <- df[,colSums(df[,!(names(df) %in% names(legend))]) != 0]

## Check dataset
table(df1$class)

## Check sizes of segments
summary(df1$sg_sz.x)

## Create list of classes that have some fuelwood biomass in them
fuelwood_classes <- legend[c(grep(pattern="forest",legend$class),
                             grep(pattern="shrubs",legend$class)
                             #,grep(pattern="trees" ,legend$class)
                             ,grep(pattern="rural" ,legend$class)
)
,]$class

(my_fuelwood_classes <- names(df1)[names(df1) %in% fuelwood_classes])

## Create list of classes that have some water
water_classes    <- legend[c(grep(pattern="water",legend$class),
                             grep(pattern="river",legend$class),
                             grep(pattern="pond" ,legend$class),
                             grep(pattern="lake" ,legend$class),
                             grep(pattern="tidal" ,legend$class))
                           ,]$class

(my_water_classes <- names(df1)[names(df1) %in% water_classes])


## Create a new reclass column: 1==Fuelwood loss, 2==Fuelwood stable, 3==The rest, 4== Water, 5==Agriculture, 6==Fuelwood Gains

### By default it is all "other land"
df1$recl <- 3


## Fuelwood stable is if it was majority of Fuelwood in both time periods
tryCatch({
  df1[
    df1$sg_sz.x > 10 &                               # size is bigger than 10 pixels (1 pixel = 1.5m*1.5m = 2.25 m2)
      df1$class %in% fuelwood_classes &              # time 2 classification says "Fuelwood"
      rowSums(df1[,my_fuelwood_classes]) > 5 ,       # time 1 classification says at least 5 pixels of "Fuelwood"
    ]$recl <- 2
}, error=function(e){cat("No such configuration\n")}
)

tryCatch({
  df1[
    df1$cloud16 > 0.5  &                        # time 2 classification says "cloud"
    rowSums(df1[,my_fuelwood_classes]) > 5 ,  # time 1 classification says at least 5 pixels of "Fuelwood"
    ]$recl <- 2
}, error=function(e){cat("No such configuration\n")}
)

## Fuelwood loss is if it was majority of Fuelwood in t1 and other than water in t2
tryCatch({
  df1[
    df1$cloud16 == 0 &
    df1$sg_sz.x > 10 &                                          # size is bigger than 10 pixels (1 pixel = 1.5m*1.5m = 2.25 m2)
    !(df1$class %in% fuelwood_classes) &                        # the time 2 classification says "Not fuelwood"
    !(df1$class %in% water_classes) &                           # the time 2 classification says "Not water"
     rowSums(df1[,my_fuelwood_classes]) > (0.75*df1$sg_sz.x) &  # The time 1 classification says "Fuelwood" for more than 70% of the segment
    abs(df1$imad) > 50                                          # IMAD indicates some change is occuring
    ,]$recl <- 1
}, error=function(e){cat("No such configuration\n")}
)

## Fuelwood gains is if it was majority of Fuelwood in period 2 only
tryCatch({
  df1[
    df1$sg_sz.x > 10 &                         # size is bigger than 10 pixels (1 pixel = 5m*5m = 25 m2)
      df1$class %in% fuelwood_classes &        # time 2 classification says "Fuelwood"
      rowSums(df1[,my_fuelwood_classes]) <= 5 , # time 1 classification says at least 5 pixels of "Fuelwood"
    ]$recl <- 6
}, error=function(e){cat("Configuration impossible \n")}
)

## WATER IF WATER IN BOTH TIME PERIODS
tryCatch({
  df1[
    df1$class %in% my_water_classes &
    rowSums(df1[,my_water_classes]) > (0.5*df1$sg_sz.x)
      ,]$recl <- 4
}, error=function(e){cat("No such configuration\n")}
) 

## AGRICULTURE/SALT PANES IS CHANGE AND AGRICULTURE/SALT PANES/WATER  IN BOTH TIME PERIODS
tryCatch({
  df1[
    df1$sg_sz.x > 10 &                                          # size is bigger than 10 pixels (1 pixel = 1.5m*1.5m = 2.25 m2)
      (df1$class %in% agri_classes |                            # the time 2 classification says "Agriculture"
         df1$class %in% water_classes) &                        # OR the time 2 classification says "Water"
      (rowSums(df1[,my_agri_classes]) ) > (0.7*df1$sg_sz.x) 

       
    &      # The time 1 classification says "Agriculture" for more than 50% of the segment
      abs(df1$imad) > 5                                         # IMAD level LOW
    ,]$recl <- 5
}, error=function(e){cat("No such configuration\n")}
)


df1[df1$sg_id == 272050,]

## Resort in the same order as it was when read. 
## always clever... shapefiles like order, they are powerful, 
## delicate and fragile in the same time, therefore they protect themselves by being bossy
df2 <- arrange(df1,sortid)
table(df2$recl)

## Export as data table
write.table(file=reclass,df2[,c("sg_id","recl")],sep=" ",quote=FALSE, col.names=FALSE,row.names=FALSE)

## Reclass the raster with the change values
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s %s",
               reclass,
               paste0(mergedir,"/","tmp_reclass.tif"),
               segs_id
               ))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(mergedir,"/","tmp_reclass.tif"),
               chg_class
               ))

system(sprintf(paste0("rm ",mergedir,"/","tmp*.tif")))

#rm(list=ls(pattern="df"))
