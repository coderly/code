module Code
  module UsesFileSystem
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

    def with_empty_tmp_folder
      before do
        @pwd = Dir.pwd
        @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
        FileUtils.mkdir_p(@tmp_dir)
        Dir.chdir(@tmp_dir)
      end

      after do
        Dir.chdir(@pwd)
        FileUtils.rm_rf(@tmp_dir)
      end
    end

    def with_file_and_content(file, content)
      before do
        @pwd = Dir.pwd
        @tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
        FileUtils.mkdir_p(@tmp_dir)
        Dir.chdir(@tmp_dir)

        create_file(file)
        set_file_content(file, content)
      end

      after do
        Dir.chdir(@pwd)
        FileUtils.rm_rf(@tmp_dir)
      end
    end

    private

    def create_file(file)
      base_name = File.basename(file)
      dir_name = File.dirname(file)
      FileUtils.mkdir_p(dir_name) if dir_name
      FileUtils.touch(file)
    end

    def set_file_content(file, content)
      File.write(file, content)
    end
  end
end