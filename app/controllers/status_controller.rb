require 'git'

class StatusController < ApplicationController
  layout 'status'

  def index
    repo = Git.open(Rails.root)

    @revision = {
      :id => repo.log.first.to_s,
      :message => repo.log.first.message
    }
  end
end
