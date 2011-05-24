dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir

require 'rake'
require 'rake/testtask'
require 'unimidi'

Rake::TestTask.new(:test) do |t|

  t.libs << "test"
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
end

platforms = ["generic", "x86_64-darwin10.7.0", "i386-mingw32", "java", "i686-linux"]

task :build do
  require "unimidi-gemspec"
  platforms.each do |platform| 
    UniMIDI::Gemspec.new(platform)
    filename = "unimidi-#{platform}.gemspec"
    system "gem build #{filename}"
    system "rm #{filename}"
  end
end
 
task :release => :build do
  platforms.each do |platform| 
    system "gem push unimidi-#{UniMIDI::VERSION}-#{platform}.gem"
  end
end

task :default => [:test]