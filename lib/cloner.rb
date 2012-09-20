module Cloner

  def make_deep_clone
    new_object = self.clone
    new_object.save
    self.class.reflections.keys.each do |k|
      new_object.send("#{k}=",self.send(k.to_s))
    end
    new_object
  end
end
