require 'code/system'

module Code
  module GitExtras

    def init
      System.call 'init'
    end

    module ClassMethods
      def setup_test_repo
        repo_path = Dir.mktmpdir
        Dir.chdir repo_path
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end
