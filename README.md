Tried:
* How to get assets to compile on Heroku - this worked after many attempts: heroku labs:enable user-env-compile (http://stackoverflow.com/questions/16124490/heroku-rails-4-could-not-connect-to-server-connection-refused)
* heroku run db:create - doesn't work
* heroku addons:add heroku-postgresql:dev - not necessary
* blew away app and started over
* added to Gemfile: gem 'rails_12factor', group: :production
* deployed again
* heroku run rake db:migrate
* heroku addons:upgrade logging:expanded - does not work
* heroku addons:add logentries:tryit
* removed git revision fingerprint reporting stuff - that worked

How to get asset_sync working:
* set env variables in heroku
* created initializer
* heroku labs:enable user-env-compile -a myapp
* move asset_sync outside :assets group - this finally worked
