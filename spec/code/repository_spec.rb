require 'code/repository'
require_relative '../support/git_extras'

module Code
  describe Repository do

    describe "self.current" do
      before(:all) do
        Repository.send :include, GitExtras
      end

      before do
        allow(System).to receive(:puts)
        Repository.setup_test_repo
      end

      it "returns a Repository instance from the URL of the current origin remote" do
        current_repo = Repository.current
        expect(current_repo.slug).to eq "testuser/codegit"
      end
    end

    describe "#organization" do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.organization).to eq "test_org"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.organization).to eq "test_org"
      end

      it "works with file system paths" do
        repo = Repository.new(url: "/home/random/path/to/git/test_org/test_name")
        expect(repo.organization).to eq "test_org"
      end
    end

    describe "#name" do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.name).to eq "test_name"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.name).to eq "test_name"
      end

      it "works with file system paths" do
        repo = Repository.new(url: "/home/random/path/to/git/test_org/test_name")
        expect(repo.name).to eq "test_name"
      end
    end

    describe "#slug" do
      it "works with 'https://' format repository urls" do
        repo = Repository.new(url: "https:/github.com/test_org/test_name.git")
        expect(repo.slug).to eq "test_org/test_name"
      end

      it "works with 'git@github.com:' format repository urls" do
        repo = Repository.new(url: "git@github.com:test_org/test_name.git")
        expect(repo.slug).to eq "test_org/test_name"
      end

      it "works with file system paths" do
        repo = Repository.new(url: "/home/random/path/to/git/test_org/test_name")
        expect(repo.slug).to eq "test_org/test_name"
      end
    end

  end
end