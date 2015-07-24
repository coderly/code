module Code
  module UsesFiles
    def self.included(group)
      group.extend(self)
    end

    def with_files(*files)
      before do
        @pwd = Dir.pwd
        @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
        FileUtils.mkdir_p(@tmp_dir)
        Dir.chdir(@tmp_dir)

        files.each do |file|
          create_file(file)
        end
      end

      after do
        Dir.chdir(@pwd)
        FileUtils.rm_rf(@tmp_dir)
      end
    end

    def create_file(file)
      base_name = File.basename(file)
      dir_name = File.dirname(file)
      FileUtils.mkdir_p(dir_name) if dir_name
      FileUtils.touch(file)
    end
  end
end