class DBFile < ActiveRecord::Base
  attr_protected []

  self.table_name = 'dbfiles'
  
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ machine }
  SEARCH_FIELDS = %w{ dbfiles.file_name dbfiles.file_path dbfiles.md5 machines.hostname }

  validates :file_name,
      format: /\A[^\/]*\z/,
      uniqueness: { scope: [ :file_path, :machine_id ],
                    message: ": You can't use the same file name and path more than once for the same machine." }
  validates :file_path,
      format: { with: /\A\//,
                message: "must begin with '/'." }


  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  has_many :children, :class_name => "DBFile"
  belongs_to :parent, :class_name => "DBFile", :foreign_key => "parent_id"
  belongs_to :container, :polymorphic => true
  belongs_to :machine 
  belongs_to :updated_user, :foreign_key => "updated_user_id", :class_name => 'User'
  belongs_to :created_user, :foreign_key => "created_user_id", :class_name => 'User'

  def setup(user_id, upload, args = nil)
    self[:created_user_id] = user_id
    self[:updated_user_id] = user_id
    if upload # Uploaded file
      self[:file_name] =  upload.original_filename
      self[:md5] = Digest::MD5.file(upload.path).hexdigest

      directory = DBFile.make_md5_path(self[:md5])
      self[:file_path] = File.join(directory,self[:md5])

      #self[:machine_id] = Machine.find(2).id # Machine ident for forecast...
      self[:machine_id] = Machine.find_by_hostname(Socket.gethostbyname(Socket.gethostname).first).id rescue nil # Machine ident for forecast...
      logger.info "No matching host found: #{Socket.gethostbyname(Socket.gethostname).first}"

      FileUtils.mkdir_p directory if !File.exists?(directory)
      # write the file
      File.open(self[:file_path], "wb") { |f| f.write(upload.read) }
      # For making looking up files easier symlink based on name/id
      directory_names = File.join(Rails.root,"paperclip/file_names/",self[:md5][0..2],self[:md5][3..5],self[:md5][6..8])
      FileUtils.mkdir_p directory_names if !File.exists?(directory_names)
      system "ln -s #{File.join(directory,self[:md5])} #{File.join(directory_names,self[:file_name])}"
    else # On a difference Machine...
      self[:file_name] = args[:file_name]
      self[:file_path] = args[:file_path]
      self[:md5] = args[:md5]
      self[:machine_id] = args[:machine_id]
    end   
  end

  def self.make_md5_path(filemd5) # Also used by 'download' to only allow sending of uploaded files.
    unless filemd5.match(/\./)
      File.join(Rails.root,"paperclip/files/",filemd5[0..2],filemd5[3..5],filemd5[6..8])
    end
  end

  def to_s(format = nil)
    case format
    when :file_path
      "#{id} - #{machine.hostname rescue ''}:#{file_path}"
    when :short
      "#{id} - #{machine.hostname rescue ''}:#{file_name.length > 20 ? file_name[0..20]+'...' : file_name}"
    else
      "#{id} - #{machine.hostname rescue ''}:#{file_name}"
    end
  end

#  def self.max_file_id
#    self.first(:order => 'file_id desc').file_id
#  end

  def select_default
    self.to_s
  end

end
