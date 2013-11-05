class Person

  PersonOptions.define_attr_readers(self)

  def initialize options=nil
    @options = PersonOptions.parse(options)
  end

end
