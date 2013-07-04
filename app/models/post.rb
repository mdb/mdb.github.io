class Post < ActiveRecord::Base
  before_save :update_or_create_slug

  attr_accessible :content, :title, :active, :tag_list, :thumbnail

  has_attached_file :thumbnail

  acts_as_taggable

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
