source('functions.R')
source_python("scrape.py")

## scrape_me is a df of games that are finished
## that are not on the server
games <- get_finished_games() %>%
  dplyr::filter(!is.na(result)) %>%
  dplyr::filter(season >= 2020)

scrape_me <- get_missing_games(games, 'raw')

if (!dir.exists('raw')) {
  dir.create('raw')
}

#testing only
#scrape_me <- scrape_me %>% filter(season == 2019 & week <= 2)

if (nrow(scrape_me) > 0) {

  n_games <- nrow(scrape_me)

  #the actual scrape
  tictoc::tic(glue::glue('Scraped {nrow(scrape_me)} games'))
  for (j in 1 : nrow(scrape_me)) {

    #testing only
    #j = 3

    game = scrape_me %>% dplyr::slice(j)

    t <- get_pbp_from_website(game$url)

    if (!is.null(t)) {
      tryCatch({
        json <- as.character(t) %>%
          jsonlite::fromJSON(flatten = T)

      }, error = function(e){cat("ERROR :",conditionMessage(e), "\n")})

      season = game$season
      week = game$week
      if (game$game_type == 'post') {
        week = ifelse(season <= 2020, week + 17, week + 18)
      }
      away = game$away_team
      home = game$home_team

      if (!dir.exists(glue::glue('raw/{season}'))) {
        dir.create(glue::glue('raw/{season}'))
      }

      #save
      saveRDS(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.rds'))
      jsonlite::write_json(json, glue::glue('raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))
      system(glue::glue('gzip raw/{season}/{season}_{formatC(week, width=2, flag=\"0\")}_{away}_{home}.json'))

      message(glue::glue('Found {season}/w{week}/{away}/{home}. {json$data$viewer$gameDetail$plays$playDescriptionWithJerseyNumbers[3]}'))

      # do some cleaning so server doesn't get clogged
      # i don't think this should be necessary anymore?
      # system('rm -r /home/ben/.seleniumwire/storage-*')
      # system('killall chromedriver', ignore.stderr = T)
      # system('killall chrome', ignore.stderr = T)

    } else {
      message(glue::glue('Nothing found for this game: {game$url}'))
    }

  }
  tictoc::toc()

  #clean up when you're done
  #prevents errors in future, hopefully
  system('killall chromedriver')
  system('killall chrome')
  # system('rm -r /home/ben/.seleniumwire/storage-*')

  #thanks to Tan for the code
  git2r::add(data_repo,'raw/*') # add specific files to staging of commit
  git2r::commit(data_repo,message = glue::glue("Automated pbp scrape ({n_games} new games) at {Sys.time()}")) # commit the staged files with the chosen message
  git2r::pull(data_repo) # pull repo (and pray there are no merge commits)

  # old code before PAT
  # uncomment this if the new system doesn't work
  # git2r::push(data_repo, credentials = git2r::cred_user_pass(username = 'guga31bb', password = paste(password))) # push commit
  # end old code

  # new code with PAT
  cred <- git2r::cred_token()
  git2r::push(data_repo, credentials = cred) # push commit

  message(paste('Successfully uploaded to GitHub at',Sys.time())) # I have cron set up to pipe this message to healthchecks.io

}


