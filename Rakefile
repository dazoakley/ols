require 'bundler'
Bundler::GemHelper.install_tasks

require 'shoulda'
require 'rake/testtask'

desc 'Run the test suite under /test'
Rake::TestTask.new do |t|
   t.libs << 'test'
   t.test_files = FileList['test/test*.rb']
   t.verbose = true
end
