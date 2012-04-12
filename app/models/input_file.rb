class InputFile < ActiveRecord::Base
  belongs_to :input
  belongs_to :format
#  belongs_to :machine ?? Will we have a machine table...
  belongs_to :user, :foreign_key => "updated_user_id"


  def self.save(upload,file_id,id)
    name =  upload['datafile'].original_filename

    directory = "paperclip/input_files/#{file_id}/"
    Dir.mkdir(directory) if !File.exists?(directory)
    directory = "paperclip/input_files/#{file_id}/#{id}/"
    Dir.mkdir(directory) if !File.exists?(directory)

    # create the file path
    path = File.join(directory, name)

    # write the file
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }

    return Digest::MD5.file(path).hexdigest
    
  end
end
