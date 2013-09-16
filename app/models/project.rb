class Project < ActiveRecord::Base
  before_save :update_or_create_slug

  validates :title, :presence => true

  has_many :project_assets

  accepts_nested_attributes_for :project_assets, :allow_destroy => true

  # Heroku hack; http://pivotallabs.com/rails-4-upgrade/
  acts_as_taggable rescue nil

  validates :title,
    :presence => true,
    :length => { :minimum => 5 }

  def permalink
    "/projects/#{self.to_param}"
  end

  def update_or_create_slug
    self.slug = self.title.try(:parameterize)
  end

  def to_param
    slug or title.parameterize
  end
end
