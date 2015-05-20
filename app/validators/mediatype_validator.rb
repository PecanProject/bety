class MediatypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !is_recognized_mediatype?(value)
      record.errors.add attribute, "-- the type portion of \"#{value}\" doesn't correspond to any recognized media type."
    end
  end

  def is_recognized_mediatype?(str)
    str =~ /\A(application|
               audio|
               chemical|
               drawing|
               image|
               i-world|
               message|
               model|
               multipart|
               music|
               paleovu|
               text|
               video|
               windows|
               www|
               x-conference|
               xgl|
               x-music|
               x-world)

               \/[a-z.0-9_-]+

               (\ \(
                    (old|compiled\ elisp)
                   \)
               )?

               \z/x
  end
end

