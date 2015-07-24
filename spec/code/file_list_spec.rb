require "code/file_list"
require_relative '../support/uses_file_system'

module Code

  describe FileList do
    include UsesFileSystem


    describe "#matching" do
      with_files("random_file", "non_random_file", "other_random_file", "last/random")

      it "returns a list of files matching the patterns" do
        list = FileList.new.matching("random")
        expect(list.length).to eq 4

        list = FileList.new.matching("random", "file")
        expect(list.length).to eq 3

        list = FileList.new.matching("file")
        expect(list.length).to eq 3

        list = FileList.new.matching("non", "random")
        expect(list.length).to eq 1
      end

    end
  end
end