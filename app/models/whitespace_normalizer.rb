class WhitespaceNormalizer

  def initialize(attrs_to_normalize)
    @attrs_to_normalize = attrs_to_normalize
  end

  def before_validation(model)
    @attrs_to_normalize.each do |attr|
      model[attr].squish!
    end
  end

end
