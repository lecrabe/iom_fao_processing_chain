packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}

packages(rgdal)
packages(raster)
packages(rgeos)

packages(ggplot2)
packages(xtable)
packages(foreign)
packages(dismo)
packages(stringr)
packages(plyr)

packages(snow)

packages(leaflet)
packages(RColorBrewer)
packages(DT)

packages(RStoolbox)
packages(e1071)
packages(randomForest)
