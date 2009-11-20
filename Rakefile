require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = "multimaster_adapter"
  s.version = File.read("VERSION").strip
  s.summary = "MultiMaster Adapter for ActiveRecord 1.x"
  s.description = "This plugin works by handling two or more connections to databases which are all masters. It also tries to check health of primary master and use another one if primary is down"
  s.homepage = "http://github.com/srozum/multimaster_adapter"
  s.email = "sergey.rozum@gmail.com"
  s.authors = ["Sergey Rozum"]
  s.files = %w(README.markdown Rakefile LICENSE init.rb) + Dir["lib/**/*"] + Dir["test/**/*"]
  File.readlines('lib/multimaster_adapter.rb').each { |line| 
    s.add_dependency($1, $2) if line =~ /^gem '(.+)'\s*,\s*'(.*)'/
  }
  s.has_rdoc = true
end

desc "write gemspec"
task :gemspec do
  filename = "#{spec.name}.gemspec"
  puts "Writing to #{filename}"
  File.open(filename, "w") { |f| f.write(spec.to_ruby) }
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_zip = true
  pkg.need_tar = true
end
