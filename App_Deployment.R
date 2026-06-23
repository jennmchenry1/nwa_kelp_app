library(rsconnect)


<<<<<<< HEAD
setwd("C:/Users/jennm/Dropbox/GITHUB/RShiny_Repos/")

# https://www.shinyapps.io/admin/#/dashboard
rsconnect::setAccountInfo(name='jennifermchenry',
                          token='C58D5A16C20AC8045B89CB73F1483BFE',
                          secret='l54+Yu5uGU1qY/viBa3oUI2iIbKPogBQ+E55kiUJ')

rsconnect::deployApp(appName = "nwa_kelp_app",account = "jennifermchenry",appDir = "nwa_kelp_app")  


rsconnect::configureApp(appName = "nwa_kelp_app", size="large",account = "jennifermchenry")
=======
setwd("C:/Users/jennm/Dropbox/GITHUB/RShiny_Repos/seagrass_bev_app/")

# https://www.shinyapps.io/admin/#/dashboard
rsconnect::setAccountInfo(name='jennifermchenry',
                          token='8B743323D6488A9A7F369D4C85467B21',
                          secret='g1CINA5+qQaKNokHbrDtqnXAbWbntUa8CYjTgkSN')

rsconnect::configureApp(appName = "seagrass_bev", size="large",account = "jennifermchenry")

rsconnect::deployApp(appName = "seagrass_bev",account = "jennifermchenry",appDir = "seagrass_bev")  
>>>>>>> bf0a8258037e7051c5c2afc27670cc3ff5225aee





