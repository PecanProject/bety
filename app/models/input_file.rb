class InputFile < ActiveRecord::Base
  belongs_to :input
  belongs_to :format
#  belongs_to :machine ?? Will we have a machine table...
  belongs_to :user, :foreign_key => "updated_user_id"

  has_many :children, :class_name => "InputFile"
  belongs_to :parent, :class_name => "InputFile", :foreign_key => "file_id"

  def to_s
    directory = "/usr/local/ebi/paperclip/input_files/#{id}/#{name}"
    if File.exists?(directory)
      link_to name, download_input_files_path(id)
    else
      name
    end
  end

  def self.savefile(upload)
    name =  upload['datafile'].original_filename

    directory = "/usr/local/ebi/paperclip/input_files/#{id}/"
    Dir.mkdir(directory) if !File.exists?(directory)

    # create the file path
    path = File.join(directory, name)

    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }

    return Digest::MD5.file(path).hexdigest
    
  end
end
