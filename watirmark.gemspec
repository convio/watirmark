$:.unshift File.expand_path("../lib", __FILE__)
require "watirmark/version"

Gem::Specification.new do |s|
  s.name = %q{watirmark}
  version = Watirmark::Version::STRING
  s.version = version
  s.authors = [%q{Hugh McGowan}]
  s.email = %q{hmcgowan@convio.com}
  s.description = %q{Watirmark is Convio's test framework}
  s.homepage = %q{http://github.com/convio/watirmark}
  s.summary = %Q{watirmark #{version}}
  s.files = Dir['lib/**/*.rb']
  s.test_files =  Dir['spec/**/*.rb']
  s.require_paths = ["lib"]
  s.add_dependency("watir") if RUBY_PLATFORM == "i386-mingw32"
  s.add_dependency("watir-webdriver")
  s.add_dependency("american_date")
  s.add_dependency("logger")
  s.add_dependency("watirmark-log")
  s.add_dependency("watirmark-bvt")
  s.add_dependency("uuid")
  s.add_dependency("nokogiri")
end

