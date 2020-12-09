# Load Ruby Core Libraries
require "time"
require "fileutils"
require "tempfile"
require "syslog"
require "yaml"
require "etc"
require "forwardable"
require "thread"

require "open4"
require "thor"
require "shellwords"

require "excon"
# Include response.inspect in error messages.
Excon.defaults[:debug_response] = true
# Excon should not retry failed requests. We handle that.
Excon.defaults[:middlewares].delete(Excon::Middleware::Idempotent)

##
# The Backup Ruby Gem
module Backup
  ##
  # Backup's internal paths
  LIBRARY_PATH       = File.join(File.dirname(__FILE__), "backup")
  STORAGE_PATH       = File.join(LIBRARY_PATH, "storage")
  SYNCER_PATH        = File.join(LIBRARY_PATH, "syncer")
  DATABASE_PATH      = File.join(LIBRARY_PATH, "database")
  COMPRESSOR_PATH    = File.join(LIBRARY_PATH, "compressor")
  ENCRYPTOR_PATH     = File.join(LIBRARY_PATH, "encryptor")
  NOTIFIER_PATH      = File.join(LIBRARY_PATH, "notifier")
  TEMPLATE_PATH      = File.expand_path("../../templates", __FILE__)

  ##
  # Autoload Backup storage files
  module Storage
    autoload :Base,       File.join(STORAGE_PATH, "base")
    autoload :Cycler,     File.join(STORAGE_PATH, "cycler")
    autoload :S3,         File.join(STORAGE_PATH, "s3")
    autoload :CloudFiles, File.join(STORAGE_PATH, "cloud_files")
    autoload :Ninefold,   File.join(STORAGE_PATH, "ninefold")
    autoload :Dropbox,    File.join(STORAGE_PATH, "dropbox")
    autoload :FTP,        File.join(STORAGE_PATH, "ftp")
    autoload :SFTP,       File.join(STORAGE_PATH, "sftp")
    autoload :SCP,        File.join(STORAGE_PATH, "scp")
    autoload :RSync,      File.join(STORAGE_PATH, "rsync")
    autoload :Local,      File.join(STORAGE_PATH, "local")
    autoload :Qiniu,      File.join(STORAGE_PATH, "qiniu")
  end

  ##
  # Autoload Backup syncer files
  module Syncer
    autoload :Base, File.join(SYNCER_PATH, "base")
    module Cloud
      autoload :Base,       File.join(SYNCER_PATH, "cloud", "base")
      autoload :LocalFile,  File.join(SYNCER_PATH, "cloud", "local_file")
      autoload :CloudFiles, File.join(SYNCER_PATH, "cloud", "cloud_files")
      autoload :S3,         File.join(SYNCER_PATH, "cloud", "s3")
    end
    module RSync
      autoload :Base,  File.join(SYNCER_PATH, "rsync", "base")
      autoload :Local, File.join(SYNCER_PATH, "rsync", "local")
      autoload :Push,  File.join(SYNCER_PATH, "rsync", "push")
      autoload :Pull,  File.join(SYNCER_PATH, "rsync", "pull")
    end
  end

  ##
  # Autoload Backup database files
  module Database
    autoload :Base,       File.join(DATABASE_PATH, "base")
    autoload :MySQL,      File.join(DATABASE_PATH, "mysql")
    autoload :PostgreSQL, File.join(DATABASE_PATH, "postgresql")
    autoload :MongoDB,    File.join(DATABASE_PATH, "mongodb")
    autoload :Redis,      File.join(DATABASE_PATH, "redis")
    autoload :Riak,       File.join(DATABASE_PATH, "riak")
    autoload :OpenLDAP,   File.join(DATABASE_PATH, "openldap")
    autoload :SQLite,     File.join(DATABASE_PATH, "sqlite")
  end

  ##
  # Autoload compressor files
  module Compressor
    autoload :Base,   File.join(COMPRESSOR_PATH, "base")
    autoload :Gzip,   File.join(COMPRESSOR_PATH, "gzip")
    autoload :Bzip2,  File.join(COMPRESSOR_PATH, "bzip2")
    autoload :PBzip2, File.join(COMPRESSOR_PATH, "pbzip2")
    autoload :Custom, File.join(COMPRESSOR_PATH, "custom")
  end

  ##
  # Autoload encryptor files
  module Encryptor
    autoload :Base,    File.join(ENCRYPTOR_PATH, "base")
    autoload :OpenSSL, File.join(ENCRYPTOR_PATH, "open_ssl")
    autoload :GPG,     File.join(ENCRYPTOR_PATH, "gpg")
  end

  ##
  # Autoload notification files
  module Notifier
    autoload :Base,      File.join(NOTIFIER_PATH, "base")
    autoload :Mail,      File.join(NOTIFIER_PATH, "mail")
    autoload :Twitter,   File.join(NOTIFIER_PATH, "twitter")
    autoload :Campfire,  File.join(NOTIFIER_PATH, "campfire")
    autoload :Prowl,     File.join(NOTIFIER_PATH, "prowl")
    autoload :Hipchat,   File.join(NOTIFIER_PATH, "hipchat")
    autoload :PagerDuty, File.join(NOTIFIER_PATH, "pagerduty")
    autoload :Pushover,  File.join(NOTIFIER_PATH, "pushover")
    autoload :Slack,     File.join(NOTIFIER_PATH, "slack")
    autoload :HttpPost,  File.join(NOTIFIER_PATH, "http_post")
    autoload :Nagios,    File.join(NOTIFIER_PATH, "nagios")
    autoload :FlowDock,  File.join(NOTIFIER_PATH, "flowdock")
    autoload :Zabbix,    File.join(NOTIFIER_PATH, "zabbix")
    autoload :DataDog,   File.join(NOTIFIER_PATH, "datadog")
    autoload :Ses,       File.join(NOTIFIER_PATH, "ses")
    autoload :Command,   File.join(NOTIFIER_PATH, "command")
  end

  ##
  # Require Backup base files
  %w[
    errors
    logger
    utilities
    archive
    binder
    cleaner
    model
    config
    cli
    package
    packager
    pipeline
    splitter
    template
    version
  ].each { |lib| require File.join(LIBRARY_PATH, lib) }
end
