# encoding: utf-8

module Backup
  class Logger
    class << self
      alias _clear! clear!
      def clear!
        saved << logger
        _clear!
      end

      def saved
        @saved ||= []
      end

      private

      alias _reset! reset!
      def reset!
        @saved = nil
        _reset!
      end
    end
  end
end
