require "rake/clean"
require "rubocop/rake_task"

CLEAN.include("tmp")
CLOBBER.include("tmp", "*.gem")

RuboCop::RakeTask.new

Dir["integration/tasks/**/*.rake"].each { |f| import f }

desc "Open a pry console in the Backup context"
task :console do
  require "pry"
  require "backup"
  ARGV.clear
  Pry.start || exit
end

def version_file
  File.join(File.expand_path("lib/backup/version.rb"))
end

def current_version
  Backup.send(:remove_const, :VERSION)
  load version_file
  Backup::VERSION
end

# Validates version numbers
#
# Valid version number format:
# - 10.0.0
# - 10.0.1.alpha
# - 10.0.1.alpha.1
# - 10.0.1.beta
# - 10.0.1.beta.1
# - 10.0.1.rc
# - 10.0.1.rc.1
def valid_version?(version)
  version =~ /\d+\.\d+\.\d+(\.(alpha|beta|rc)(\.\d+)?)?/
end

def current_branch
  `git rev-parse --abbrev-ref HEAD`.chomp
end

desc "Release new Backup gem version. Use this to release a new version."
task :release do # rubocop:disable Metrics/BlockLength
  puts "Current version: #{current_version}"
  print "Enter new version: "
  new_version = $stdin.gets.chomp

  unless valid_version?(new_version)
    abort "ERROR: Invalid version number: #{new_version.inspect}"
  end

  puts "Creating new version: #{new_version}"

  lines = File.readlines(version_file)
  File.open(version_file, "w+") do |file|
    lines.each do |line|
      if line =~ /VERSION =/
        file.puts %(  VERSION = "#{new_version}")
      else
        file.write line
      end
    end
  end

  # Check if file saved correctly
  unless current_version == new_version
    abort "ERROR: Versions don't match!\n"\
      "Current version:#{current_version}\n"\
      "New version: #{new_version}"
  end

  puts `gem build backup.gemspec`

  puts "Pushing to repository.."
  puts `git commit -m "Release v#{new_version} [ci skip]" #{version_file}`
  puts `git tag #{new_version}`
  puts `git push origin #{new_version} #{current_branch}`

  puts "Publishing Backup version #{new_version}"
  puts `gem push backup-#{new_version}.gem`

  puts "Backup version #{new_version} released!"
end

namespace :ci do
  desc "Run all quality and test tasks"
  task test: ["rubocop", "docker:test:all"]
end

namespace :docker do # rubocop:disable Metrics/BlockLength
  directory "tmp"
  directory "tmp/test_data"

  desc "Build a Docker image for Backup itself"
  task :build do
    sh "docker build -t ruby_backup_runner:latest ."
  end

  desc "Start a container environment with an interactive shell"
  task shell: [:prepare] do
    sh "docker run -e RUBYPATH='/usr/local/bundle/bin:/usr/local/bin' " \
       "-v $PWD:/usr/src/backup -it ruby_backup_tester:latest /bin/bash"
  end

  desc "Remove Docker containers for Backup"
  task :clean do
    containers = `docker ps -a | grep 'ruby_backup_*' | awk '{ print $1 }'`
      .tr("\n", " ")
    unless containers.empty?
      `docker stop #{containers}`
      `docker rm #{containers}`
    end
  end

  desc "Remove Docker containers and images for Backup"
  task clobber: [:clean] do
    images = `docker images | grep 'ruby_backup_*' | awk '{ print $3 }'`
      .tr("\n", " ")
    `docker rmi #{images}` unless images.empty?
  end

  task :prepare do
    sh "docker-compose build"
  end

  namespace :test do
    desc "Run all tests with Docker Compose"
    task all: ["tmp", "tmp/test_data"] do
      sh "docker-compose run ruby_backup_tester " \
         "./integration/bin/wait-for-it.sh -h postgres -p 5432 -- " \
         "rake docker:test:run_all"
    end

    task run_all: ["docker:test:run_spec", "docker:test:run_integration"]

    desc "Run integration tests with Docker Compose"
    task :integration do
      sh "docker-compose run ruby_backup_tester " \
         "./integration/bin/wait-for-it.sh -h postgres -p 5432 -- " \
         "rake docker:test:run_integration"
    end

    task run_integration: ["tmp", "tmp/test_data", "db:create"] do
      sh "ruby -Ilib -S rspec ./integration/acceptance/"
    end

    desc "Run RSpec tests with Docker Compose"
    task :spec do
      sh "docker-compose run ruby_backup_tester " \
         "rake docker:test:run_spec"
    end

    task :run_spec do
      sh "ruby -Ilib -S rspec ./spec/"
    end
  end
end
