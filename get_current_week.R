`%>%`<-magrittr::`%>%`

get_current_week <- function() {

  # get season
  s <- dplyr::if_else(
    lubridate::month(lubridate::today("GMT")) >= 9,
    lubridate::year(lubridate::today("GMT")) ,
    lubridate::year(lubridate::today("GMT")) - 1
  )

  # Find the first Monday of September
  day1 <- lubridate::as_date(paste(s, "09-01", sep="-"))
  week1 <- as.POSIXlt(seq(day1, length.out=7, by="day"))
  monday1 <- week1[week1$wday == 1]

  # NFL season starts 4 days later
  first_game <- (monday1 + lubridate::days(3)) %>% lubridate::as_date()

  # current week number of NFL season is 1 + how many weeks have elapsed since first game
  # (ie first game is week 1)
  current_week <- 1 +
    lubridate::days(lubridate::today("America/New_York") - first_game) %>%
    .$day %>%
    magrittr::divide_by_int(7)

  if (current_week <= 1) current_week <- 1

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
