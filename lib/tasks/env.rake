desc "Set environment variables"

namespace :env do

  # Somewhat of a workaround preventing the need to store hard-coded
  # environment variables in the heroku.yml
  # TODO: research a better way to handle this
  desc "Set the neccessary AWS environment variables on Heroku"
  task :heroku do
    puts "Setting heroku $AWS_ACCESS_KEY_ID to its local value..."
    system("heroku config:set AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']}")

    puts "Setting heroku $AWS_SECRET_ACCESS_KEY to its local value..."
    system("heroku config:set AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']}")
  end
end
