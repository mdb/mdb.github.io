class Post < ActiveRecord::Base
  attr_accessible :content, :title, :tags_attributes

  validates :title,
    :presence => true,
    :length => { :minimum => 5 }

  has_many :tags
                               
  accepts_nested_attributes_for :tags,
    :allow_destroy => :true,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
end
