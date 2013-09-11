namespace :db do
  desc "Start the dev database"
  task :start_dev do
    system("pg_ctl -D /usr/local/var/postgres -l log/pg.log start")
  end
end
