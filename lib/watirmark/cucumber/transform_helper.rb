class String
  def camelcase
    gsub(/(^|_| )(.)/) { $2.upcase }
  end
end

# This is a globally accessible static hash to
# store all models declared by the test automation. Making it available
# allows us to use the model values as table parameters in the gherkin!
class DataModels < Hash
  include Singleton
end

module TransformHelper
  def self.find_class_by_name(classname)
    ObjectSpace.each_object(Class) do |klass|
      if klass.inspect =~ /(^|:)#{classname}$/
        return klass
      end
    end
    raise LoadError, "Class '#{classname}' not found!"
  end
end
