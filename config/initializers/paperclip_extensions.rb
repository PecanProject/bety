#From: http://mediumexposure.com/set-paperclip-use-hashed-file-paths/

Paperclip::Attachment.interpolations[:hashed_path] = lambda do |attachment, style|
  attachment.instance.md5
end
