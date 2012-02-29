##Override the class to prevent files from being removed when others 
##are uploaded.
#module Paperclip
#  class Attachment 
#    def queue_existing_for_delete #:nodoc:
#      return if original_filename.blank?
##      @queued_for_delete += [:original, *@styles.keys].uniq.map do |style|
#        path(style) if exists?(style)
#      end.compact
#      @instance[:"#{@name}_file_name"]    = nil
#      @instance[:"#{@name}_content_type"] = nil
#      @instance[:"#{@name}_file_size"]    = nil
#    end
#  end
#end

class Raw < ActiveRecord::Base
  belongs_to :site
  belongs_to :format
  belongs_to :user
  has_many :raws_documents

  accepts_nested_attributes_for :raws_documents, :allow_destroy => true, :reject_if => proc { |attributes| attributes['doc'].blank? }
  #accepts_nested_attributes_for :raws_documents, :allow_destroy => true

  comma do
    id
    site_id
    format_id
    filepath
    start_date
    end_date
    notes
    created_at
    updated_at
    user_id
    access_level
  end

  #default_scope lambda { {:conditions => ["access_level >= ?",current_user.access_level]  }}


  named_scope :all_limited, lambda { |access_lev| 
    {:conditions => ["access_level >= ?",access_lev] }
  }
  def site_filepath
    "#{site} #{filepath}"
  end
  def to_s
    site_filepath
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["raws.id", "raws.filepath"]
  end
end
