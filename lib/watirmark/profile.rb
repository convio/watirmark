require 'ruby-prof'

class Profiler
  def self.profile(options={}, &block)
    RubyProf.start
    beginning = Time.now
    puts '-----------------------'
    puts options[:name]
    puts '-----------------------'
    block.call
    result = RubyProf.stop
    result.eliminate_methods!([/IO/, /Net::/, /Global/])
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, :min_percent=> (options[:min_percent] || 1))
    puts "----> Time elapsed #{Time.now - beginning} seconds"
  end
end


#require 'watirmark/profile'
# Profiler.profile(:name => "#{element.keyword}, #{element}") do

