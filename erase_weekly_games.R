`%>%`<-magrittr::`%>%`
source('get_current_week.R')

games <- readRDS(url("https://github.com/leesharpe/nfldata/blob/master/data/games.rds?raw=true")) %>%
  dplyr::filter(season == max(season))

season <- max(games$season)

week <- get_current_week()

pattern <- glue::glue("{season}_{formatC(week, width=2, flag=\"0\")}_*")

files <- list.files(
  path = glue::glue("raw/{season}"),
  pattern
  )

for (file in files) {
  
  message(glue::glue("Erasing raw/{season}/{file}"))
  
  file.remove(glue::glue("raw/{season}/{file}"))
}

message("Erasing completed.")
