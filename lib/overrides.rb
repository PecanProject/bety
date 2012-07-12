module Overrides
  # Include related tables in xml and json
  def to_json(options = {})
    options.merge!(:include => self.class.reflections.keys.select { |x| self.send(x).loaded? rescue false } )
    super(options)
  end

  def to_xml(options = {})
    options.merge!(:include => self.class.reflections.keys.select { |x| self.send(x).loaded? rescue false } )
    super(options)
  end
end
