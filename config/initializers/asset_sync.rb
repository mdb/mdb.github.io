# Since this gem is only loaded with the assets group, we have to check to
# # see if it's defined before configuring it.
if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = ENV['FOG_DIRECTORY']
    config.aws_access_key_id = ENV['AWS_ACCESS_KEY']
    config.aws_secret_access_key = ENV['AWS_SECRET_KEY']
    config.fog_directory = ENV['FOG_DIRECTORY']

    # Fail silently. Useful for environments such as Heroku
    config.fail_silently = false
  end
end
