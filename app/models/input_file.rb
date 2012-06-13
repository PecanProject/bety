class InputFile < ActiveRecord::Base
  belongs_to :input
  belongs_to :format
#  belongs_to :machine ?? Will we have a machine table...
  belongs_to :user, :foreign_key => "updated_user_id"

  has_many :children, :class_name => "InputFile"
  belongs_to :parent, :class_name => "InputFile", :foreign_key => "file_id"

  def savefile(user_id,new_file)
    current_user_id = user_id
    updated_user_id = user_id
    if new_file['upload']
      upload = new_file['upload']
      self[:file_name] =  upload['datafile'].original_filename

      directory = "/usr/local/ebi/paperclip/input_files/#{self[:file_id]}/"
      Dir.mkdir(directory) if !File.exists?(directory)

      # create the file path
      self[:file_path] = File.join(directory, self[:file_name])

      # write the file
      File.open(self[:file_path], "wb") { |f| f.write(upload['datafile'].read) }

      self[:md5] = Digest::MD5.file(file_path).hexdigest
    else
      self[:file_name] = new_file['file_name']
      self[:file_path] = new_file['file_path']
    end   
  end

  def to_s
    directory = "/usr/local/ebi/paperclip/input_files/#{id}/#{name}"
    if File.exists?(directory)
      link_to name, download_input_files_path(id)
    else
      name
    end
  end

end
