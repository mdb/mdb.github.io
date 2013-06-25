class Tag < ActiveRecord::Base
  belongs_to :post
  attr_accessible :name
  before_save :update_or_create_slug

  def permalink
    "/tags/#{self.to_param}"
  end

  def update_or_create_slug
    self.slug = self.name.try(:parameterize)
  end

  def to_param
    slug or name.parameterize
  end
end
