library(tidyverse)
combine_roster_data <- function() {
  start <- lubridate::as_date("2020-09-10") # Thursaday Week 1 2020
  weeks <- lubridate::days(lubridate::today("UTC")-start) %>%
    .$day %>%
    magrittr::divide_by_int(7)

  roster_raw <- purrr::map_dfr(0:weeks, function(x, s){
    day <- s + lubridate::dweeks(x)
    filename <- glue::glue('{lubridate::year(day)}_{format.Date(day, "%m")}_{format.Date(day, "%d")}_roster.rds?raw=true')
    path <- glue::glue("https://github.com/guga31bb/nflfastR-raw/blob/master/roster/{filename}")
    return(readRDS(url(path)))
  }, start) %>%
    janitor::clean_names() %>%
    dplyr::mutate(ind = 1:dplyr::n())

  dates <- roster_raw %>% dplyr::select(ind, scrape_day, scrape_point)

  rem_dupl <- roster_raw %>%
    dplyr::select(-c("scrape_day", "scrape_point")) %>%
    dplyr::na_if("") %>%
    dplyr::select("ind", "team_abbr", "player", "no", "pos") %>%
    dplyr::group_by(team_abbr, player, no) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::pull("ind")

  roster <- roster_raw %>%
    dplyr::select(-c("scrape_day", "scrape_point")) %>%
    dplyr::na_if("") %>%
    dplyr::filter(ind %in% rem_dupl) %>%
    dplyr::left_join(dates, by = "ind") %>%
    dplyr::mutate(
      teamPlayers.firstName = player %>% stringr::str_split_fixed(" ", 2) %>% .[,1],
      teamPlayers.lastName = player %>% stringr::str_split_fixed(" ", 2) %>% .[,2]
      # team.nick = team_name %>% stringr::str_split_fixed(" ", 2) %>% .[,2]
      # teamPlayers.suffix = teamPlayers.lastName %>% stringr::str_split_fixed(" ", 2) %>% .[,2]
      # name = glue::glue("{stringr::str_sub(teamPlayers.firstName, 1, 1)}.{teamPlayers.lastName}")
    ) %>%
    dplyr::select(
      team.season = season,
      teamPlayers.displayName = player,
      teamPlayers.firstName,
      teamPlayers.lastName,
      teamPlayers.status = status,
      teamPlayers.position = pos,
      teamPlayers.birthDate = birthdate,
      teamPlayers.collegeName = college,
      teamPlayers.jerseyNumber = no,
      teamPlayers.height = height,
      teamPlayers.weight = weight,
      team.abbr = team_abbr,
      team.fullName = team_name,
      # team.nick,
      scrape_dt = scrape_point
    ) %>%
    dplyr::arrange(team.season, team.abbr)

  out <- readRDS(url("https://github.com/guga31bb/nflfastR-data/blob/master/roster-data/roster.rds?raw=true")) %>%
    dplyr::bind_rows(roster) %>%
    dplyr::mutate(
      pbp_name = glue::glue("{stringr::str_sub(teamPlayers.firstName, 1, 1)}.{teamPlayers.lastName}") %>% as.character(),
      pbp_name = dplyr::case_when(
        teamPlayers.displayName == "Robert Griffin III" ~ "R.Griffin III",
        teamPlayers.displayName == "Gardner Minshew" ~ "G.Minshew II",
        TRUE ~ pbp_name
      ),
      join = stringr::str_extract(pbp_name, "(?<=\\.)[:graph:]+(?=\\b)"),
      team.abbr = dplyr::case_when(
        team.abbr == "STL" ~ "LA",
        team.abbr == "SD" ~ "LAC",
        team.abbr == "OAK" ~ "LV",
        TRUE ~ team.abbr
      )
    ) %>%
    dplyr::select(team.season, team.abbr, pbp_name, teamPlayers.jerseyNumber, dplyr::everything())

  return(out)
}
roster <- combine_roster_data()

seasons <- 2011:2019
pbp <- purrr::map_df(seasons, function(x) {
  readRDS(
    url(
      glue::glue("https://raw.githubusercontent.com/guga31bb/nflfastR-data/master/data/play_by_play_{x}.rds")
    )
  )
}) #%>% 
  # nflfastR::clean_pbp() # added fresh clean_pbp after some changes

pass <- pbp %>% 
  group_by(season, posteam, passer, passer_jersey_number) %>% 
  summarise(plays = n()) %>% 
  mutate(join = stringr::str_extract(passer, "(?<=\\.[:space:]?)[:graph:]+(?=\\b)")) %>% 
  filter(!is.na(passer), !is.na(passer_jersey_number)) %>% 
  left_join(
    roster, 
    by = c("season" = "team.season", "posteam" = "team.abbr", "join", "passer_jersey_number" = "teamPlayers.jerseyNumber")
  )

rec <- pbp %>% 
  group_by(season, posteam, receiver, receiver_jersey_number) %>% 
  summarise(plays = n()) %>% 
  mutate(join = stringr::str_extract(receiver, "(?<=\\.[:space:]?)[:graph:]+(?=\\b)")) %>% 
  filter(!is.na(receiver), !is.na(receiver_jersey_number)) %>% 
  left_join(
    roster, 
    by = c("season" = "team.season", "posteam" = "team.abbr", "join", "receiver_jersey_number" = "teamPlayers.jerseyNumber")
  )

rush <- pbp %>% 
  group_by(season, posteam, rusher, rusher_jersey_number) %>% 
  summarise(plays = n()) %>% 
  mutate(join = stringr::str_extract(rusher, "(?<=\\.[:space:]?)[:graph:]+(?=\\b)")) %>% 
  filter(!is.na(rusher), !is.na(rusher_jersey_number)) %>% 
  left_join(
    roster, 
    by = c("season" = "team.season", "posteam" = "team.abbr", "join", "rusher_jersey_number" = "teamPlayers.jerseyNumber")
  )

join_error_rush <- rush %>% filter(is.na(teamPlayers.position))
join_error_rec <- rec %>% filter(is.na(teamPlayers.position))
join_error_pass <- pass %>% filter(is.na(teamPlayers.position))

join_error <- dplyr::bind_rows(join_error_pass, join_error_rec, join_error_rush) %>% 
  dplyr::select(
    season, posteam, join, plays,
    passer, passer_jersey_number,
    rusher, rusher_jersey_number,
    receiver, receiver_jersey_number
  ) %>% 
  dplyr::arrange(desc(plays)) #%>% 
  # dplyr::filter(plays > 5)
