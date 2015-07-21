require "code/branch"
require "code/system"

module Code


  describe Branch do

    def setup_test_repo(options = {})

      defaults = {
        name: "test_repo",
        origins: [],
        branches: []
      }

      options = defaults.merge(options)

      repo_path = Dir.mktmpdir(options[:name])
      Dir.chdir repo_path

      System.call "init"
      System.call "config user.email \"test@hotmail.com\""
      System.call "config user.name \"Chuck Norris\""
      System.exec "touch README"
      System.call "add -A"
      System.call "commit -m \"initial commit\""

      options[:origins].each do |origin|
        System.call "remote add #{origin.name} #{origin.url}"
      end

      options[:branches].each do |branch|
        System.call "branch #{branch}"
      end
    end

    def checkout_branch(name)
      System.call("checkout #{name}")
    end

    before do
      allow(System).to receive(:puts)
    end

    describe "self.all_names" do
      it "returns names of all branches in the repo as strings" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        branch_names = Branch.all_names

        expect(branch_names.length).to eq 3
        expect(branch_names[0]).to eq "master"
        expect(branch_names[1]).to eq "test-branch-1"
        expect(branch_names[2]).to eq "test-branch-2"
      end
    end

    describe "self.all" do
      it "returns Branch instances for all branches in the repo" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        branches = Branch.all

        expect(branches.length).to eq 3
        expect(branches[0]).to be_a(Branch)
        expect(branches[1]).to be_a(Branch)
        expect(branches[2]).to be_a(Branch)
        expect(branches[0].name).to eq "master"
        expect(branches[1].name).to eq "test-branch-1"
        expect(branches[2].name).to eq "test-branch-2"
      end
    end

    describe "self.exists?" do
      it "works" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        expect(Branch.exists? "master").to eq true
        expect(Branch.exists? "test-branch-1").to eq true
        expect(Branch.exists? "test-branch-2").to eq true
        expect(Branch.exists? "test-branch-3").to eq false
      end
    end

    describe "self.current" do
      it "returns a Branch instance for the current git branch" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        current_branch = Branch.current
        expect(current_branch).to be_a Branch
        expect(current_branch.name).to eq "master"

        checkout_branch "test-branch-1"

        current_branch = Branch.current
        expect(current_branch).to be_a Branch
        expect(current_branch.name).to eq "test-branch-1"
      end
    end
  end
end