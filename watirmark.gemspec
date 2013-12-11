$:.unshift File.expand_path('../lib', __FILE__)
require 'watirmark/version'

Gem::Specification.new do |s|
  s.name = %q{watirmark}
  version = Watirmark::Version::STRING
  s.version = version
  s.authors = [%q{Hugh McGowan}]
  s.email = %q{hmcgowan@convio.com}
  s.description = %q{Watirmark is an MVC test framework for watir-webdriver}
  s.homepage = %q{http://github.com/convio/watirmark}
  s.summary = %Q{watirmark #{version}}
  s.files = Dir['lib/**/*.rb', 'generators/**/*', 'bin/**/*']
  s.test_files = Dir['spec/**/*.rb']
  s.executables = 'watirmark'
  s.require_paths = %w(lib)
  s.add_dependency('watir-webdriver', '>= 0.6.1')
  s.add_dependency('selenium-webdriver', '~> 2.38.0')
  s.add_dependency('american_date', '~> 1.0')
  s.add_dependency('logger', '~> 1.2.8')
  s.add_dependency('uuid', '~> 2.3.6')
  s.add_dependency('nokogiri', '~> 1.5.10')
  s.add_dependency('thor')
  s.add_dependency('activesupport', '~> 3.1.11')
  s.add_dependency('i18n', '~> 0.6.1')
end

