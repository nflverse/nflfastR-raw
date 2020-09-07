source("combine_roster_data.R")

# run this every thurs early in morning
scrape_day <- as.character(lubridate::today())

if (lubridate::month(scrape_day) %in% c(9, 10, 11, 12, 1, 2)) {
  
  suppressWarnings(
    roster <- combine_roster_data(scrape_day)
  )
  
  saveRDS(roster, 'roster/roster_cleaned.rds')
  
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
  
  message(paste('Successfully uploaded to GitHub at',Sys.time()))
  
}
