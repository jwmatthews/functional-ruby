$:.push File.join(File.dirname(__FILE__), 'lib')
$:.push File.join(File.dirname(__FILE__), 'tasks/support')

require 'rubygems'
require 'bundler/gem_tasks'
require 'rspec'
require 'rspec/core/rake_task'

require 'functional'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new(:spec)
$:.unshift 'tasks'
Dir.glob('tasks/**/*.rake').each do|rakefile|
  load rakefile
end

task :default => [:spec]
