class ProjectAsset < ActiveRecord::Base
  belongs_to :project
  has_attached_file :project_asset #'project_asset' refers to prefix in fields
end
