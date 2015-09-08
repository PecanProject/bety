class Mimetype < ActiveRecord::Base

  # VALIDATION

  validates :type_string,
      presence: true,
      mediatype: true # see app/validations

  def to_s
    type_string
  end

end
