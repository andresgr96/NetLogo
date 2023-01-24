setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
theme_set(
  theme_light() + theme(legend.position = "top")
)

plot1 <- ggplot(dataSetNew, aes(x = turnLights, y = avgCarWaitingTime))+
  geom_boxplot()+
  xlab("Lights")+
  ylab("Car Waiting Time")+
  theme_bw()

plot1 + stat_summary(fun.y=mean, geom="point", shape=23, size=4) + facet_grid(numberOfCars ~ numberOfPedestrians)

plot2 <- ggplot(dataSetNew, aes(x = turnLights, y = avgPedestrianWaitingTime))+
  geom_boxplot()+
  xlab("Lights")+
  ylab("Pedestrian Waiting Time")+
  theme_bw()

plot2 + stat_summary(fun.y=mean, geom="point", shape=23, size=4) + facet_grid(numberOfCars ~ numberOfPedestrians)


