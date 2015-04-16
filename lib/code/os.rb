module Code
  module System
    class OS

      def self.windows?
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      end

      def self.unix?
        !self.windows?
      end

      def self.osx?
        (/darwin/ =~ RUBY_PLATFORM) != nil
      end

      def self.linux?
         self.unix? and not self.osx?
      end

      def self.open_command
        "open" if self.osx?
        "xdg-open" if self.linux?
      end
    end
  end
end
