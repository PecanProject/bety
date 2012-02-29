class RawsDocument < ActiveRecord::Base

  belongs_to :raw

  has_attached_file :doc, 
                    :path => "/rails/ebi/paperclip/raws/:id/:basename.:extension", 
                    :url => "/bety/raws/download?document_id=:id"

  validates_attachment_size :doc, :less_than => 100.megabytes
  
end
