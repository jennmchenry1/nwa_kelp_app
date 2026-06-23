library(rsconnect)



setwd("C:/Users/Jenn/Dropbox/GITHUB/RShiny_Repos/nwa_kelp_app/")

# https://www.shinyapps.io/admin/#/dashboard
rsconnect::setAccountInfo(name='jennifermchenry',
                          token='C58D5A16C20AC8045B89CB73F1483BFE',
                          secret='l54+Yu5uGU1qY/viBa3oUI2iIbKPogBQ+E55kiUJ')

# rsconnect::deployApp(appName = "nwa_kelp_app",account = "jennifermchenry",appDir = "nwa_kelp_app")  


rsconnect::configureApp(appName = "nwa_kelp_app", size="large",account = "jennifermchenry")


