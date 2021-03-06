class ItemContentLanguage < ActiveRecord::Base
  belongs_to :language
  belongs_to :item

  attr_accessible :language_id, :language, :item_id, :item

  validates :language_id, :presence => true
  #validates :item_id, :presence => true
end
