module Backup
  module Config
    # Context for loading user config.rb and model files.
    class DSL
      class Error < Backup::Error; end
      Model = Backup::Model

      class << self
        private

        # List the available database, storage, syncer, compressor, encryptor
        # and notifier constants. These are used to define constant names within
        # Backup::Config::DSL so that users may use a constant instead of a string.
        # Nested namespaces are represented using Hashs. Deep nesting supported.
        #
        # Example, instead of:
        #  database "MySQL" do |mysql|
        #  sync_with "RSync::Local" do |rsync|
        #
        # You can do:
        #  database MySQL do |mysql|
        #  sync_with RSync::Local do |rsync|
        #
        def add_dsl_constants
          create_modules(
            DSL,
            [ # Databases
              ["MySQL", "PostgreSQL", "MongoDB", "Redis", "Riak", "OpenLDAP", "SQLite"],
              # Storages
              ["S3", "CloudFiles", "Dropbox", "FTP",
               "SFTP", "SCP", "RSync", "Local", "Qiniu"],
              # Compressors
              ["Gzip", "Bzip2", "PBzip2", "Custom"],
              # Encryptors
              ["OpenSSL", "GPG"],
              # Syncers
              [
                { "Cloud" => ["CloudFiles", "S3"] },
                { "RSync" => ["Push", "Pull", "Local"] }
              ],
              # Notifiers
              ["Mail", "Twitter", "Campfire", "Prowl",
               "Hipchat", "PagerDuty", "Pushover", "HttpPost", "Nagios",
               "Slack", "FlowDock", "Zabbix", "Ses", "DataDog", "Command"]
            ]
          )
        end

        def create_modules(scope, names)
          names.flatten.each do |name|
            if name.is_a?(Hash)
              name.each do |key, val|
                create_modules(get_or_create_empty_module(scope, key), [val])
              end
            else
              get_or_create_empty_module(scope, name)
            end
          end
        end

        def get_or_create_empty_module(scope, const)
          if scope.const_defined?(const)
            scope.const_get(const)
          else
            scope.const_set(const, Module.new)
          end
        end
      end

      add_dsl_constants # add constants on load

      attr_reader :_config_options

      def initialize
        @_config_options = {}
      end

      # Allow users to set command line path options in config.rb
      [:root_path, :data_path, :tmp_path].each do |name|
        define_method name do |path|
          _config_options[name] = path
        end
      end

      # Allows users to create preconfigured models.
      def preconfigure(name, &block)
        unless name.is_a?(String) && name =~ /^[A-Z]/
          raise Error, "Preconfigured model names must be given as a string " \
                        "and start with a capital letter."
        end

        if DSL.const_defined?(name)
          raise Error, "'#{name}' is already in use " \
                        "and can not be used for a preconfigured model."
        end

        DSL.const_set(name, Class.new(Model))
        DSL.const_get(name).preconfigure(&block)
      end
    end
  end
end
