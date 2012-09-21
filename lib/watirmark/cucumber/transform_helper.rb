class String
  def camelcase
    gsub(/(^|_| )(.)/) { $2.upcase }
  end
end

# This is a globally accessible static hash to
# store all models declared by the test automation. Making it available
# allows us to use the models values as table parameters in the gherkin!
DataModels = {}


DebugModelValues = Hash.new{|h,k| h[k]=Hash.new}



