require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

gem 'ci_reporter'
require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit


DEPENDENCIES = []
DEPENDENCIES << Gem::Dependency.new('json', '>=1.1.3')
DEPENDENCIES << Gem::Dependency.new('fireeagle', '>=0.8')
DEPENDENCIES << Gem::Dependency.new('daemons', '>=1.0.10')
DEPENDENCIES << Gem::Dependency.new('oos4ruby', '>=0.1.6')
DEPENDENCIES << Gem::Dependency.new('calavera-mechanize', '>=0.7.8')
DEPENDENCIES << Gem::Dependency.new('tmail', '>=1.2.3.1')
DEPENDENCIES << Gem::Dependency.new('thoughtbot-shoulda', '>=2.0')

TEST_FILES = FileList['test/unit/*test.rb']

desc "Run all tests"
task :test => [:test_unit]

Rake::TestTask.new("test_unit") do |t|
  t.test_files = TEST_FILES
  t.verbose = false  
end

def install_gem(*args)
  cmd = []
  cmd << "#{'sudo ' unless Gem.win_platform?}gem install --no-ri --no-rdoc"
  sh cmd.push(*args.flatten).join(" ")
end

desc 'Install the required dependencies'
task :setup do
#  sh "#{'sudo ' unless Gem.win_platform?}gem sources -a http://gems.github.com"

  installed = Gem::SourceIndex.from_installed_gems
  DEPENDENCIES.select { |dep|
    installed.search(dep.name, dep.version_requirements).empty? }.each do |dep|
      puts "Installing #{dep} ..."
      install_gem dep.name, "-v '#{dep.version_requirements.to_s}'"
    end
end

desc "Run code-coverage analysis using rcov"
task :coverage do
  install_gem('rcov', '-s http://gem.github.com') if Gem::SourceIndex.from_installed_gems.search('rcov').empty?
  rm_rf "coverage"
  system "rcov --sort coverage -Ilib #{TEST_FILES.join(' ')}"
end
