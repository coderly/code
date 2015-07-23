require 'code/system'

module Code
  module GitExtras

    module ClassMethods

      def test_repo_origin
        "https:/github.com/testuser/codegit"
      end

      def setup_test_repo
        repo_path = Dir.mktmpdir('codegit')
        Dir.chdir repo_path

        System.call 'init'
        System.call 'config user.email "test@hotmail.com"'
        System.call 'config user.name "Chuck Norris"'
        System.exec 'touch README'
        System.call 'add -A'
        System.call 'commit -m "initial commit"'
        System.call "remote add origin #{test_repo_origin}"
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end
end
