module Helpers
  def http_login
    username = Mdb::Application.config.username
    password = Mdb::Application.config.password
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
