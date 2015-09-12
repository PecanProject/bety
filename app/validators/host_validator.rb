class HostValidator < ActiveModel::EachValidator

  include ValidationConstants

  def validate_each(record, attribute, value)
    if !is_host_address?(value)
      record.errors.add attribute, 'is not a valid host name'
    end
  end

  def is_host_address?(str)
    str =~ Regexp.new('\A' + HOST + '\z')
  end
end

