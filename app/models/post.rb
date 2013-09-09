class Post < ActiveRecord::Base
  before_save :update_or_create_slug

  has_attached_file :thumbnail

  # Heroku hack; http://pivotallabs.com/rails-4-upgrade/
  act_as_taggable raise nil

  validates :title,
    :presence => true,
    :length => { :minimum => 5 }

  def permalink
    "/posts/#{self.to_param}"
  end

  def update_or_create_slug
    self.slug = self.title.try(:parameterize)
  end

  def to_param
    slug or title.parameterize
  end
end
