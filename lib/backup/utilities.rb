module Backup
  module Utilities
    class Error < Backup::Error; end

    UTILITIES_NAMES = %w[
      tar cat split sudo chown hostname
      gzip bzip2 pbzip2
      mongo mongodump mysqldump innobackupex
      pg_dump pg_dumpall redis-cli riak-admin
      gpg openssl
      rsync ssh
      sendmail exim
      send_nsca
      zabbix_sender
    ].freeze

    # @api private
    class DSL
      def initialize(utils)
        @utilities = utils
      end

      # Helper methods to allow users to set the path for all utilities in the
      # .configure block.
      #
      # Utility names with dashes (`redis-cli`) will be set using method calls
      # with an underscore (`redis_cli`).
      UTILITIES_NAMES.each do |util_name|
        define_method util_name.tr("-", "_") do |raw_path|
          path = File.expand_path(raw_path)

          unless File.executable?(path)
            raise Utilities::Error, <<-EOS
              The path given for '#{util_name}' was not found or not executable.
              Path was: #{path}
            EOS
          end

          @utilities.utilities[util_name] = path
        end
      end

      # Allow users to set the +tar+ distribution if needed. (:gnu or :bsd)
      def tar_dist(val)
        Utilities.tar_dist(val)
      end
    end

    class << self
      ##
      # Configure the path to system utilities used by Backup.
      #
      # Backup will attempt to locate any required system utilities using a
      # +which+ command call. If a utility can not be found, or you need to
      # specify an alternate path for a utility, you may do so in your
      # +config.rb+ file using this method.
      #
      # Backup supports both GNU and BSD utilities.
      # While Backup uses these utilities in a manner compatible with either
      # version, the +tar+ utility requires some special handling with respect
      # to +Archive+s. Backup will attempt to detect if the +tar+ command
      # found (or set here) is GNU or BSD. If for some reason this fails,
      # this may be set using the +tar_dist+ command shown below.
      #
      #   Backup::Utilities.configure do
      #     # General Utilites
      #     tar      '/path/to/tar'
      #     tar_dist :gnu   # or :bsd
      #     cat      '/path/to/cat'
      #     split    '/path/to/split'
      #     sudo     '/path/to/sudo'
      #     chown    '/path/to/chown'
      #     hostname '/path/to/hostname'
      #
      #     # Compressors
      #     gzip    '/path/to/gzip'
      #     bzip2   '/path/to/bzip2'
      #     pbzip2  '/path/to/pbzip2'
      #
      #     # Database Utilities
      #     mongo       '/path/to/mongo'
      #     mongodump   '/path/to/mongodump'
      #     mysqldump   '/path/to/mysqldump'
      #     pg_dump     '/path/to/pg_dump'
      #     pg_dumpall  '/path/to/pg_dumpall'
      #     redis_cli   '/path/to/redis-cli'
      #     riak_admin  '/path/to/riak-admin'
      #
      #     # Encryptors
      #     gpg     '/path/to/gpg'
      #     openssl '/path/to/openssl'
      #
      #     # Syncer and Storage
      #     rsync   '/path/to/rsync'
      #     ssh     '/path/to/ssh'
      #
      #     # Notifiers
      #     sendmail  '/path/to/sendmail'
      #     exim      '/path/to/exim'
      #     send_nsca '/path/to/send_nsca'
      #     zabbix_sender '/path/to/zabbix_sender'
      #   end
      #
      # These paths may be set using absolute paths, or relative to the
      # working directory when Backup is run.
      def configure(&block)
        DSL.new(self).instance_eval(&block)
      end

      def tar_dist(val)
        # the acceptance tests need to be able to reset this to nil
        @gnu_tar = val.nil? ? nil : val == :gnu
      end

      def gnu_tar?
        return @gnu_tar unless @gnu_tar.nil?
        @gnu_tar = !!run("#{utility(:tar)} --version").match(/GNU/)
      end

      def utilities
        @utilities ||= {}
      end

      private

      ##
      # Returns the full path to the specified utility.
      # Raises an error if utility can not be found in the system's $PATH
      def utility(name)
        name = name.to_s.strip
        raise Error, "Utility Name Empty" if name.empty?

        utilities[name] ||= `which '#{name}' 2>/dev/null`.chomp
        raise Error, <<-EOS if utilities[name].empty?
          Could not locate '#{name}'.
          Make sure the specified utility is installed
          and available in your system's $PATH, or specify it's location
          in your 'config.rb' file using Backup::Utilities.configure
        EOS

        utilities[name].dup
      end

      ##
      # Returns the name of the command name from the given command line.
      # This is only used to simplify log messages.
      def command_name(command)
        parts = []
        command = command.split(" ")
        command.shift while command[0].to_s.include?("=")
        parts << command.shift.split("/")[-1]
        if parts[0] == "sudo"
          until command.empty?
            part = command.shift
            if part.include?("/")
              parts << part.split("/")[-1]
              break
            else
              parts << part
            end
          end
        end
        parts.join(" ")
      end

      ##
      # Runs a system command
      #
      # All messages generated by the command will be logged.
      # Messages on STDERR will be logged as warnings.
      #
      # If the command fails to execute, or returns a non-zero exit status
      # an Error will be raised.
      #
      # Returns STDOUT
      def run(command)
        name = command_name(command)
        Logger.info "Running system utility '#{name}'..."

        begin
          out = ""
          err = ""
          ps = Open4.popen4(command) do |_pid, stdin, stdout, stderr|
            stdin.close
            out = stdout.read.strip
            err = stderr.read.strip
          end
        rescue Exception => e
          raise Error.wrap(e, "Failed to execute '#{name}'")
        end

        unless ps.success?
          raise Error, <<-EOS
            '#{name}' failed with exit status: #{ps.exitstatus}
            STDOUT Messages: #{out.empty? ? "None" : "\n#{out}"}
            STDERR Messages: #{err.empty? ? "None" : "\n#{err}"}
          EOS
        end

        unless out.empty?
          Logger.info(out.lines.map { |line| "#{name}:STDOUT: #{line}" }.join)
        end

        unless err.empty?
          Logger.warn(err.lines.map { |line| "#{name}:STDERR: #{line}" }.join)
        end

        out
      end

      def reset!
        utilities.clear
        @gnu_tar = nil
      end
    end

    # Allows these utility methods to be included in other classes,
    # while allowing them to be stubbed in spec_helper for all specs.
    module Helpers
      [:utility, :command_name, :run].each do |name|
        define_method name do |arg|
          Utilities.send(name, arg)
        end
        private name
      end

      private

      def gnu_tar?
        Utilities.gnu_tar?
      end
    end
  end
end
