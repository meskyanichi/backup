module Backup
  module Compressor
    class PBzip2 < Base
      ##
      # Specify the level of compression to use.
      #
      # Values should be a single digit from 1 to 9.
      # Note that setting the level to either extreme may or may not
      # give the desired result. Be sure to check the documentation
      # for the compressor being used.
      #
      # The default `level` is 9.
      attr_accessor :level

      ##
      # The number of processors to be used with Parallel BZIP2
      # (pbzip2).
      #
      # Default is autodetection to use all.
      attr_accessor :processors

      ##
      # Creates a new instance of Backup::Compressor::PBzip2
      def initialize(&block)
        load_defaults!

        @level ||= false

        instance_eval(&block) if block_given?

        @cmd = "#{utility(:pbzip2)}#{options}"
        @ext = ".bz2"
      end

      private

      def options
        o = ""
        o << " -#{@level}" if @level
        o << " -p#{@processors}" if @processors
        o
      end
    end
  end
end
