class Post < ActiveRecord::Base
  before_save :update_or_create_slug

  attr_accessible :content, :title, :tags_attributes

  validates :title,
    :presence => true,
    :length => { :minimum => 5 }

  has_many :tags

  accepts_nested_attributes_for :tags,
    :allow_destroy => :true,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

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
