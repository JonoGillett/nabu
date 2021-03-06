class CollectionAdmin < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

# RAILS bug - can't save collection_admin without collection_admin having been saved
#  validates :collection_id, :presence => true
  validates :user_id, :presence => true
  validates :collection_id, :uniqueness => {:scope => [:collection_id, :user_id]}

  attr_accessible :collection_id, :collection, :user_id, :user
end
