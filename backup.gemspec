# encoding: utf-8

require File.expand_path("lib/backup/version")

Gem::Specification.new do |gem|
  gem.name        = "backup"
  gem.version     = Backup::VERSION
  gem.authors     = "Michael van Rooijen"
  gem.email       = "meskyanichi@gmail.com"
  gem.homepage    = "https://github.com/backup/backup"
  gem.license     = "MIT"
  gem.summary     = "Provides an elegant DSL in Ruby for performing backups "\
    "on UNIX-like systems."
  gem.description = <<-EOS.gsub(/\s+/, " ").strip
    Backup is a RubyGem, written for UNIX-like operating systems, that allows
    you to easily perform backup operations on both your remote and local
    environments. It provides you with an elegant DSL in Ruby for modeling your
    backups.  Backup has built-in support for various databases, storage
    protocols/services, syncers, compressors, encryptors and notifiers which
    you can mix and match. It was built with modularity, extensibility and
    simplicity in mind.
  EOS

  gem.files = `git ls-files -- lib bin templates README.md LICENSE`.split("\n")
  gem.require_path  = "lib"
  gem.executables   = ["backup"]

  gem.required_ruby_version = ">= 2.0"

  gem.add_dependency "thor", "0.18.1"
  gem.add_dependency "open4", "1.3.0"
  gem.add_dependency "fog", "1.28.0"
  gem.add_dependency "excon", "~> 0.44"
  gem.add_dependency "unf", "0.1.3" # for fog/AWS
  gem.add_dependency "dropbox-sdk", "1.6.5"
  gem.add_dependency "net-ssh", "3.2.0"
  gem.add_dependency "net-scp", "1.2.1"
  gem.add_dependency "net-sftp", "2.1.2"
  gem.add_dependency "mail", "2.6.3" # patched
  gem.add_dependency "pagerduty", "2.0.0"
  gem.add_dependency "twitter", "5.5.0"
  gem.add_dependency "hipchat", "1.0.1"
  gem.add_dependency "flowdock", "0.4.0"
  gem.add_dependency "json", "1.8.2"
  gem.add_dependency "dogapi", "1.11.0"
  gem.add_dependency "aws-ses", "0.5.0"
  gem.add_dependency "qiniu", "6.5.1"
  gem.add_dependency "nokogiri", "~> 1.6.0"

  gem.add_development_dependency "rubocop", "0.45.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "2.14.1"
  gem.add_development_dependency "mocha", "0.14.0"
  gem.add_development_dependency "timecop", "0.7.1"
  gem.add_development_dependency "activerecord"
  gem.add_development_dependency "mysql2"
  gem.add_development_dependency "iconv"
  gem.add_development_dependency "pg"
  gem.add_development_dependency "mongo"
  gem.add_development_dependency "bson_ext"
  gem.add_development_dependency "redis"
  gem.add_development_dependency "riak-client"
end
