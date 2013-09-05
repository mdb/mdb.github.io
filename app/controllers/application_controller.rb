class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_fingerprint

  private
  def get_fingerprint
    if Mdb::Application.config.git_fingerprint_activated
      @fingerprint = Mdb::Application.config.fingerprint.merge(git_info)
    end
  end

  def git_info
    repo = Git.open(Rails.root)

    {
      :git_commit_id => repo.log.first.to_s,
      :git_commit_message => repo.log.first.message,
      :git_branch => repo.current_branch
    }
  end
end
