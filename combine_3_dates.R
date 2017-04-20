####################################################################################
####### Object:  Merge results from classification and assign change value
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2016/11/08                                          
####################################################################################

merge_time <- Sys.time()

mapperiod1  <- paste0(result_dir,tile,"_1994_2003/change/tile_",tile,"_change_reclass.tif")
mapperiod2  <- paste0(result_dir,tile,"_2003_2016/change/tile_",tile,"_change_reclass.tif")

################################################################################
## Combine 
system(sprintf("gdal_calc.py -A %s -B %s -C %s --C_band 1 --outfile=%s --calc=\"%s\"",
               mapperiod1,
               mapperiod2,
               t2_input,
               paste0(comb_dir,"tmp.tif"),
               "(A*10+B)*(C>0)"
               ))



################################################################################
## Compute stats
system(sprintf("oft-stat -i %s -um %s -o %s",
               paste0(comb_dir,"tmp.tif"),
               paste0(comb_dir,"tmp.tif"),
               paste0(comb_dir,"stattmp.txt")
))

df <- read.table(paste0(comb_dir,"stattmp.txt"))[,1:2]
names(df) <- c("comb_class","size")
df <- arrange(df,comb_class)

df



################################################################################
## Two-dates classes
################################################################################

## 1== Fuelwood loss
## 2== Fuelwood stable 
## 3== Other land
## 4== Water
## 5== Agriculture
## 6== Fuelwood Gains

################################################################################
################################################################################
## Create new reclassified class for 3-dates
df$newclass <- 0

df[df$comb_class == 01,]$newclass <- 112
df[df$comb_class == 02,]$newclass <- 111
df[df$comb_class == 03,]$newclass <- 222
df[df$comb_class == 04,]$newclass <- 99
df[df$comb_class == 05,]$newclass <- 55
df[df$comb_class == 06,]$newclass <- 221

df[df$comb_class == 10,]$newclass <- 122
df[df$comb_class == 11,]$newclass <- 212
df[df$comb_class == 12,]$newclass <- 121
df[df$comb_class == 13,]$newclass <- 122
df[df$comb_class == 14,]$newclass <- 122
df[df$comb_class == 15,]$newclass <- 122
df[df$comb_class == 16,]$newclass <- 121

df[df$comb_class == 20,]$newclass <- 222
df[df$comb_class == 21,]$newclass <- 112
df[df$comb_class == 22,]$newclass <- 111
df[df$comb_class == 23,]$newclass <- 222
df[df$comb_class == 24,]$newclass <- 55
df[df$comb_class == 25,]$newclass <- 55
df[df$comb_class == 26,]$newclass <- 111

df[df$comb_class == 30,]$newclass <- 222
df[df$comb_class == 31,]$newclass <- 212
df[df$comb_class == 32,]$newclass <- 221
df[df$comb_class == 33,]$newclass <- 222
df[df$comb_class == 34,]$newclass <- 222
df[df$comb_class == 35,]$newclass <- 55
df[df$comb_class == 36,]$newclass <- 221

df[df$comb_class == 40,]$newclass <- 99
df[df$comb_class == 41,]$newclass <- 212
df[df$comb_class == 42,]$newclass <- 111
df[df$comb_class == 43,]$newclass <- 222
df[df$comb_class == 44,]$newclass <- 99
df[df$comb_class == 45,]$newclass <- 55
df[df$comb_class == 46,]$newclass <- 221

df[df$comb_class == 50,]$newclass <- 55
df[df$comb_class == 51,]$newclass <- 212
df[df$comb_class == 52,]$newclass <- 211
df[df$comb_class == 53,]$newclass <- 222
df[df$comb_class == 54,]$newclass <- 55
df[df$comb_class == 55,]$newclass <- 55
df[df$comb_class == 56,]$newclass <- 221

df[df$comb_class == 60,]$newclass <- 111
df[df$comb_class == 61,]$newclass <- 212
df[df$comb_class == 62,]$newclass <- 211
df[df$comb_class == 63,]$newclass <- 212
df[df$comb_class == 64,]$newclass <- 211
df[df$comb_class == 65,]$newclass <- 212
df[df$comb_class == 66,]$newclass <- 121

write.table(df,paste0(comb_dir,"reclass.txt"),quote=FALSE, col.names=FALSE,row.names=FALSE)

################################################################################
## Reclassify
system(sprintf("(echo %s; echo 1; echo 1; echo 3; echo 0) | oft-reclass -oi  %s %s",
               paste0(comb_dir,"reclass.txt"),
               paste0(comb_dir,"tmp_reclass.tif"),
               paste0(comb_dir,"tmp.tif")
               ))


################################################################################
## Sieve by 9 pixels, allow diagonals
system(sprintf("gdal_sieve.py -8 -st 9 %s %s",
               paste0(comb_dir,"tmp_reclass.tif"),
               paste0(comb_dir,"tmp_sieve.tif")
))


pct <- data.frame(cbind(
  unique(df$newclass)[order(unique(df$newclass))],
  c("yellow","blue","darkgreen","red","orange","red4","lightgreen","orange2","turquoise","grey")
  ))
colors()
pct1 <- data.frame(cbind(pct$X1,col2rgb(pct$X2)[1,],col2rgb(pct$X2)[2,],col2rgb(pct$X2)[3,]))
write.table(pct1,paste0(comb_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(comb_dir,"color_table.txt"),
               paste0(comb_dir,"tmp_sieve.tif"),
               paste0(comb_dir,"tmp_reclass_pct.tif")
))

################################################################################
## Compress
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"tmp_reclass_pct.tif"),
               paste0(comb_dir,"reclass_94_03_16.tif")
))

#system(sprintf("rm -r %s",
 #              paste0(comb_dir,"tmp*.tif")))


################################################################################
## Clip LC MAP 
system(sprintf("oft-clip.pl %s %s %s",
               paste0(comb_dir,"reclass_94_03_16.tif"),
               train_input,
               paste0(comb_dir,"tmp_lc_map.tif")
))

system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"tmp_lc_map.tif"),
               paste0(comb_dir,"lc_map_clip.tif")
))

system(sprintf("rm -r %s",
               paste0(comb_dir,"tmp*.tif")))

################################################################################
system(sprintf("oft-zonal.py -i %s -um %s -o %s",
               paste0(comb_dir,"lc_map_clip.tif"),
               paste0(comb_dir,"reclass_94_03_16.tif"),
               paste0(comb_dir,"combination_change_lcmap.txt")
               ))

combinations <- read.table(paste0(comb_dir,"combination_change_lcmap.txt"))

lc_trans <- data.frame(cbind(
  combinations[,1],
  combinations[,2:ncol(combinations)]*1.5*1.5/10000
  )
)

names(lc_trans) <- c("change_class","total","nodata",legend[1:(ncol(lc_trans)-3),2])
lc_trans
write.csv(lc_trans,paste0(rootdir,"lc_transitions_20170418.csv"),row.names = F)
# 
## Combine change product and land cover product
system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --co COMPRESS=LZW --calc=\"%s\"",
               paste0(comb_dir,"reclass_94_03_16.tif"),
               paste0(comb_dir,"lc_map_clip.tif"),
               paste0(comb_dir,"tmp.tif"),
"
(B>0)*(A>0)*(
(B==2)*222+
(B==3)*222+
(B==4)*((A==55)*111+(A==99)*111++(A==111)*111+(A==121)*121+(A==211)*211+(A==212)*121+(A==222)*222)+
(B==7)*222+
(B==9)*111+
(B==10)*((A==55)*55+(A==99)*55+(A==111)*55+(A==112)*112+(A==121)*55+(A==122)*122+(A>200)*55)+
(B==11)*((A==55)*55+(A==99)*55+(A==111)*112+(A==112)*112+(A==121)*55+(A==122)*122+(A>200)*55)+
(B==12)*222+
(B==13)*99 +
(B==15)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*112+(A==121)*121+(A==122)*122+(A==211)*121+(A==212)*121+(A==221)*121+(A==222)*222)+
(B==18)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*111+(A==121)*121+(A==122)*122+(A==211)*121+(A==212)*121+(A==221)*121+(A==222)*222)+
(B==19)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*112+(A==121)*121+(A==122)*122+(A==211)*211+(A==212)*121+(A==221)*221+(A==222)*222)+ 
(B==20)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*112+(A==121)*121+(A==122)*122+(A==211)*121+(A==212)*121+(A==221)*121+(A==222)*222)+
(B==21)*55 +
(B==22)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*112+(A==121)*121+(A==122)*121+(A==211)*121+(A==212)*121+(A==221)*121+(A==222)*222)+
(B==23)*((A==55)*55+(A==99)*99+(A>100)*222)+
(B==24)*((A==55)*55+(A==99)*222+(A==111)*111+(A==112)*112+(A==121)*121+(A==122)*121+(A==211)*211+(A==212)*121+(A==221)*221+(A==222)*222)+   
(B==25)*222+
(B==29)*99)"
))

df1 <- data.frame(cbind(c(55,99,111,112,121,122,211,212,221,222),
                       c(8,9,1,3,7,4,5,7,6,2)))

write.table(df1,paste0(comb_dir,"reclass2.txt"),quote=FALSE, col.names=FALSE,row.names=FALSE)

################################################################################
## Reclassify
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s %s",
               paste0(comb_dir,"reclass2.txt"),
               paste0(comb_dir,"tmp_reclass2.tif"),
               paste0(comb_dir,"tmp.tif")
))




pct <- data.frame(cbind(
  1:9,
  c("darkgreen","grey","red","orange","turquoise","lightgreen","greenyellow","yellow","blue")
))
colors()

pct2 <- data.frame(cbind(pct$X1,col2rgb(pct$X2)[1,],col2rgb(pct$X2)[2,],col2rgb(pct$X2)[3,]))
write.table(pct2,paste0(comb_dir,"color_table2.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(comb_dir,"color_table2.txt"),
               paste0(comb_dir,"tmp_reclass2.tif"),
               paste0(comb_dir,"tmp_reclass_pct2.tif")
))

################################################################################
## Compress
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(comb_dir,"tmp_reclass_pct2.tif"),
               paste0(comb_dir,"lc2015_change940316.tif")
))

# system(sprintf("rm -r %s",
#                paste0(comb_dir,"tmp*.tif")))
