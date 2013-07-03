class Post < ActiveRecord::Base
  before_save :update_or_create_slug

  attr_accessible :content, :title

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
