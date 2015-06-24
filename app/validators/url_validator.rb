require 'validation_constants'
class UrlValidator < ActiveModel::EachValidator

  include ValidationConstants

  def validate_each(record, attribute, value)
    if !is_url_or_parenthesized_or_empty?(value)
      record.errors.add attribute, 'is not a valid URL.  Use a schema-qualified URL.  To use arbitrary strings, enclose them in parentheses.'
    end
  end

  def is_url_or_parenthesized_or_empty?(str)
    str =~ Regexp.new('\A(|' + URL + '|\(.+\))\z')
  end
end

