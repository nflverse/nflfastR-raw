library(tidyverse)
source("combine_roster_data.R")
roster <- combine_roster_data("2020-09-03")

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
  dplyr::arrange(desc(plays))