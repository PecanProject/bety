#From: http://mediumexposure.com/set-paperclip-use-hashed-file-paths/

# RAILS3 changed syntax for newest version of paperclip
Paperclip.interpolates :hashed_path do |attachment, style|
  attachment.instance.md5
end
