module Code
  module System
    class OS

      def self.current
        new(platform_string: RUBY_PLATFORM)
      end

      def initialize(platform_string:)
        @platform_string = platform_string
      end

      def windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ @platform_string) != nil
      end

      def unix?
        !windows?
      end

      def osx?
        (/darwin/ =~ @platform_string) != nil
      end

      def linux?
         unix? and not osx?
      end

      def open_command
        command = "open" if osx?
        command = "xdg-open" if linux?

        command
      end
    end
  end
end
