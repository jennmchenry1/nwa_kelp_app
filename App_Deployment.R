library(rsconnect)


setwd("C:/Users/jennm/Dropbox/GITHUB/RShiny_Repos/seagrass_bev_app/")

# https://www.shinyapps.io/admin/#/dashboard
rsconnect::setAccountInfo(name='jennifermchenry',
                          token='8B743323D6488A9A7F369D4C85467B21',
                          secret='g1CINA5+qQaKNokHbrDtqnXAbWbntUa8CYjTgkSN')

rsconnect::configureApp(appName = "seagrass_bev", size="large",account = "jennifermchenry")

rsconnect::deployApp(appName = "seagrass_bev",account = "jennifermchenry",appDir = "seagrass_bev")  





