`%>%`<-magrittr::`%>%`

teams <- nflfastR::teams_colors_logos %>%
  dplyr::mutate(
    pagename = stringr::str_replace_all(stringr::str_to_lower(team_name), " ", "-")
  ) %>%
  dplyr::select(team_abbr, team_name, pagename) %>%
  dplyr::filter(!team_abbr %in% c("LAR", "OAK", "SD", "STL"))

inds <- seq_along(teams$pagename)
future::plan("multiprocess")

progressr::with_progress({
  p <- progressr::progressor(along = inds)
  roster_raw <-
    # purrr::map_dfr(inds, function(x) {
    furrr::future_map_dfr(inds, function(x) {
      roster <- glue::glue("https://www.nfl.com/teams/{teams$pagename[[x]]}/roster") %>%
        xml2::read_html() %>%
        rvest::html_table() %>%
        .[[1]] %>%
        tibble::as_tibble() %>%
        dplyr::mutate(
          team_abbr = teams$team_abbr[[x]],
          team_name = teams$team_name[[x]]
        )
      Sys.sleep(.1)
      p(sprintf("x=%g", x))
      return(roster)
    }) %>%
    dplyr::select(team_abbr, team_name, dplyr::everything()) %>%
    dplyr::mutate(
      scrape_day = lubridate::today("UTC"),
      scrape_point = lubridate::now("UTC"),
      season = dplyr::if_else(
        lubridate::month(scrape_day) < 3,
        lubridate::year(scrape_day)-1,
        lubridate::year(scrape_day)
      )
    )
})

scrape_day = lubridate::today("UTC")

saveRDS(roster_raw, glue::glue('roster/{lubridate::year(scrape_day)}_{format.Date(scrape_day, "%m")}_{format.Date(scrape_day, "%d")}_roster.rds'))


#github setup stuff
if (grepl("Documents",getwd())){
  path <- ".."
} else { ### server
  path <- "/home/ben"
}
password = as.character(read.delim(glue::glue('{path}/gh.txt'))$pw)
data_repo <- git2r::repository('./') # Set up connection to repository folder

git2r::add(data_repo,'roster/*') # add specific files to staging of commit
git2r::commit(data_repo, message = glue::glue("Updating at {Sys.time()}")) # commit the staged files with the chosen message
git2r::pull(data_repo) # pull repo (and pray there are no merge commits)
git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit

message(paste('Successfully uploaded to GitHub at',Sys.time())) # I have cron set up to pipe this message to healthchecks.io


