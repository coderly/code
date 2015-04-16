require 'code/repository'

module Code
  describe Repository do

    describe '#organization' do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.organization).to eq "test_org"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.organization).to eq "test_org"
      end
    end

    describe '#name' do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.name).to eq "test_name"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.name).to eq "test_name"
      end
    end

    describe '#slug' do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.slug).to eq "test_org/test_name"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.slug).to eq "test_org/test_name"
      end
    end

  end
end