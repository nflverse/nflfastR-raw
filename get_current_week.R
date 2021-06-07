`%>%`<-magrittr::`%>%`

get_current_week <- function() {
  
  # get list of games from current season
  games <- readRDS(url("https://github.com/leesharpe/nfldata/blob/master/data/games.rds?raw=true")) %>%
    dplyr::filter(season == get_current_season()) %>%
    dplyr::arrange(gameday)
  
  games_first_week <- games %>% dplyr::filter(week == 1)
  
  max_week <- max(games$week)
  
  # get date of first game
  first_game <- lubridate::as_date(dplyr::first(games_first_week$gameday))
  
  # current week number of NFL season is 1 + how many weeks have elapsed since first game
  # (ie first game is week 1)
  current_week <- 1 +
    lubridate::days(lubridate::today("America/New_York") - first_game) %>%
    .$day %>%
    magrittr::divide_by_int(7)
  
  if (current_week <= 1) current_week <- 1
  if (current_week >= max_week) current_week <- max_week
  
  return(current_week)
  
}

get_current_season <- function() {
  
  s <- dplyr::if_else(
    lubridate::month(lubridate::today("GMT")) >= 9,
    lubridate::year(lubridate::today("GMT")) ,
    lubridate::year(lubridate::today("GMT")) - 1
  )
  
  return(s)
  
}
