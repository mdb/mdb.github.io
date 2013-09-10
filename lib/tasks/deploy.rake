task :after_deploy do
  HerokuSan.project.each_app do |stage|
    puts "---> Precompiling asssets & uploading to the CDN"
    system("heroku run rake assets:precompile --app #{stage.app}")
  end
end
