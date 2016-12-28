require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Open a pry console in the Backup context'
task :console do
  require 'pry'
  require 'backup'
  ARGV.clear
  Pry.start || exit
end

# Activate all dependencies in :production group in Gemfile
# (along with their dependencies) according to Gemfile.lock
# and update backup.gemspec to require exactly those versions.
desc 'Rebuild gemspec with production dependencies'
task :gemspec => :binstub do
  # avoids gem specifications loaded by rake, rubygems-bundler, etc...
  script = %q(
    #!/usr/bin/env ruby
    require 'bundler'
    Bundler.setup(:production)

    ignored_gems = ['bundler', 'io-console', 'did_you_mean']
    lines = File.readlines('backup.gemspec')
    File.open('backup.gemspec', 'w') do |file|
      lines.each do |line|
        file.write line
        break if line == "  # Gem Dependencies\n"
      end
      file.puts '  # Generated by `rake gemspec`. Do Not Edit.'
      Gem.loaded_specs.sort_by {|name, spec| name }.each do |name, spec|
        unless ignored_gems.include?(name)
          file.puts "  gem.add_dependency '#{ name }', '= #{ spec.version }'"
        end
      end
      file.puts 'end'
    end
  )
  system('ruby', '-e', script) # no shell expansion
  puts `git diff --color backup.gemspec`
end

# Activate all dependencies in :production group in Gemfile
# (along with their dependencies) according to Gemfile.lock
# and update bin/backup to require exactly those versions.
desc 'Rebuild binstub with production dependencies'
task :binstub do
  # avoids gem specifications loaded by rake, rubygems-bundler, etc...
  script = %q(
    #!/usr/bin/env ruby
    require 'bundler'
    Bundler.setup(:production)

    ignored_gems = ['bundler', 'io-console', 'did_you_mean']
    lines = File.readlines('bin/backup')
    File.open('bin/backup', 'w') do |file|
      lines.each do |line|
        file.write line
        break if line == "# Gem Dependencies\n"
      end
      file.puts '# Generated by `rake binstub`. Do Not Edit.'
      Gem.loaded_specs.sort_by {|name, spec| name }.each do |name, spec|
        unless ignored_gems.include?(name)
          file.puts "gem '#{ name }', '= #{ spec.version }'"
        end
      end
      file.puts
      file.puts 'require File.expand_path("../../lib/backup", __FILE__)'
      file.puts 'Backup::CLI.start'
    end
  )
  system('ruby', '-e', script) # no shell expansion
  puts `git diff --color bin/backup`
end

desc 'Update version, commit, tag and build gem'
task :release => :gemspec do
  unless `git diff backup.gemspec`.chomp.empty? && `git diff bin/backup`.chomp.empty?
    abort <<-EOS.gsub(/^ +/, '')
      \nRelease Aborted! Dependencies were not up-to-date.
      These should have been updated with `rake gemspec` and committed
      along with the updated Gemfile.lock. VM specs will need to be run
      again against these dependencies.
    EOS
  end

  lines = File.readlines('lib/backup/version.rb')
  current = lines.select {|line| line =~ /^  VERSION/ }[0].match(/'(.*)'/)[1]
  print "Current Version: #{ current }\nEnter New Version: "
  version = $stdin.gets.chomp

  abort 'Invalid Version' unless version =~ /^\d+\.\d+\.\d+$/

  File.open('lib/backup/version.rb', 'w') do |file|
    lines.each do |line|
      if line =~ /^  VERSION/
        file.puts "  VERSION = '#{ version }'"
      else
        file.write line
      end
    end
  end

  puts `git commit -m 'Release v#{ version } [ci skip]' lib/backup/version.rb`
  `git tag #{ version }`
  exec 'gem build backup.gemspec'
end
