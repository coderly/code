# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','code','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'code'
  s.version = Code::VERSION
  s.author = 'Venkat'
  s.email = 'venkat@coderly.com'
  s.homepage = 'http://www.coderly.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Our command line toolbelt for common tasks'

# Add your other files here if you make them
  s.files = %w(
    bin/code
    lib/code/version.rb
    lib/code.rb
  )

  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'code'
  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
  s.add_development_dependency('aruba')
  s.add_development_dependency('rspec')

  s.add_runtime_dependency('gli','2.8.0')
  s.add_runtime_dependency('hub')
end
