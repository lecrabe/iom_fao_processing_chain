####################################################################################
####### Object:  Match histogram of 2 images and merge
####### AOI   :  Bangladesh
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/04/03                                        
####################################################################################

####### working directory
workdir <- "/home/dannunzio/Documents/iom_change_detection/satellite_images/"
setwd(workdir)

####### packages
options(stringsAsFactors=FALSE)
library(foreign)
library(plyr)
library(rgeos)
library(rgdal)
library(raster)
library(ggplot2)
library(outliers)

input1 <- "spot16_2.tif"
input2 <- "spot16_3_clip.tif"

####### Read rasters and determine common intersection extent
r1 <- brick(input1)
r2 <- brick(input2)

e <- extent(intersect(r1,r2))

####### Polygonize
poly <- Polygons(list(Polygon(cbind(
  c(e@xmin,e@xmin,e@xmax,e@xmax,e@xmin),
  c(e@ymin,e@ymax,e@ymax,e@ymin,e@ymin))
)),1)

####### Convert to SpatialPolygon
sp_poly <- SpatialPolygons(list(poly))

####### Shoot randomly points on the intersection, extract values from both rasters
pts <- spsample(sp_poly,n=500,"random")

h1 <- data.frame(extract(x = r1,y = pts))
h2 <- data.frame(extract(x = r2,y = pts))

names(h1) <- paste0("b",1:nbands(r1))
names(h2) <- paste0("b",1:nbands(r2))
band <- 2
####### For each band, GLM of dataset 1 vs dataset 2 and normalized raster 2 as output
for(band in 1:nbands(r1)){
      hh <- data.frame(cbind(h1[,paste0("b",band)],h2[,paste0("b",band)]))
      
      hh <- hh[hh$X1 != 0,]
      hh <- hh[hh$X2 != 0,]
      
      glm12 <- glm(hh$X1 ~ hh$X2)
      hh$residuals <- residuals(glm12)
      hh$score<-scores(hh$residuals,type="z")
      
      outlier <- hh[abs(hh$score)>2,]
      plot(X2 ~ X1,hh,col="darkgrey")
      points(X2 ~ X1,outlier,col="red")
      
      hh <- hh[abs(hh$score)<=2,]
      glm12 <- glm(hh$X1 ~ hh$X2)

      i12 <- glm12$coefficients[1]
      c12 <- glm12$coefficients[2]
      
      tmp_norm <- raster(r2,band)*c12 + i12
      assign(paste0("norm_12_b",band),tmp_norm)
      }

####### Assemble bands into a stack and export
r2_norm_12 <- brick(norm_12_b1,norm_12_b2,norm_12_b3,norm_12_b4)
writeRaster(r2_norm_12,"tmp_r2_norm.tif")

####### Merge datasets into one final product
system(sprintf("gdal_merge.py -o %s -v -n 0 -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,input1),
               paste0(workdir,"tmp_r2_norm.tif")
))

####### Compress and delete temporary files
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(workdir,"tmp_merge.tif"),
               paste0(workdir,"merge_normalized.tif")
))

system(sprintf("rm -r %s",
               paste0(workdir,"tmp*.tif")
               ))
