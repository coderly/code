require "code/branch"
require "code/system"
require "code/pull_request"

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

    describe "self.coerce_patterns" do
      it "returns an array consisting of provided patterns" do
        patterns = Branch.coerce_patterns 'abc', 'def', '123'

        expect(patterns.length).to eq 3
        expect(patterns[0]).to eq 'abc'
        expect(patterns[1]).to eq 'def'
        expect(patterns[2]).to eq '123'
      end
    end

    describe "self.matching" do
      it "finds the branch matching the patterns" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1"])

        expect(Branch.matching('test', 'branch', '1').name).to eq 'test-branch-1'
      end

      it "returns the first branch that matches the patterns" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        expect(Branch.matching('test', 'branch').name).to eq 'test-branch-1'
      end
    end

    describe "self.exists?" do
      it "returns true for a localy known branch, false otherwise" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        expect(Branch.exists? "master").to eq true
        expect(Branch.exists? "test-branch-1").to eq true
        expect(Branch.exists? "test-branch-2").to eq true
        expect(Branch.exists? "test-branch-3").to eq false
      end
    end

    #TODO: "self.merged"

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

    describe "self.master" do
      it "returns a Branch instance named 'master'" do
        master_branch = Branch.master

        expect(master_branch).to be_a Branch
        expect(master_branch.name).to eq 'master'
      end
    end

    describe "self.development" do
      it "returns a Branch instance named 'development'" do
        development_branch = Branch.development

        expect(development_branch).to be_a Branch
        expect(development_branch.name).to eq 'development'
      end
    end

    describe "self.create" do
      it "makes a system call to create a branch and returns a branch instance" do
        expect(System).to receive(:call).with("branch test_branch")

        branch = Branch.create("test_branch")

        expect(branch).to be_a Branch
        expect(branch.name).to eq "test_branch"
      end
    end

    describe "self.find" do
      it "creates a new Branch instance with specified name, but makes no System.call" do
        expect(System).not_to receive(:call)

        branch = Branch.find("test_branch")

        expect(branch).to be_a Branch
        expect(branch.name).to eq "test_branch"
      end
    end

    describe "#==" do
      it "compares by branch name" do
        branch_a = Branch.find "branch-a"
        branch_b = Branch.find "branch-b"
        other_branch_a = Branch.find "branch-a"

        expect(branch_a == branch_b).to eq false
        expect(branch_a == other_branch_a).to eq true
        expect(branch_b == other_branch_a).to eq false
      end
    end

    describe "#matches?" do
      it "returns true if the branch name matches all the patterns" do
        branch = Branch.find "test-branch"

        expect(branch.matches? "test").to eq true
        expect(branch.matches? "test", "branch").to eq true
        expect(branch.matches? "branch").to eq true
        expect(branch.matches? "test-branch").to eq true
      end

      it "returns false if the branch name matches some or none of the patterns" do
        branch = Branch.find "test-branch"

        expect(branch.matches? "test_branch").to eq false
        expect(branch.matches? "tst").to eq false
        expect(branch.matches? "tst", "test").to eq false
      end
    end

    describe "#exists" do

      it "calls System.result and returns the result" do
        test_branch_1 = Branch.find("test-branch-1")

        expect(System).to receive(:result).with("git show-ref refs/heads/test-branch-1").and_return("something")
        expect(test_branch_1.exists?).to eq true


        expect(System).to receive(:result).with("git show-ref refs/heads/test-branch-1").and_return("")
        expect(test_branch_1.exists?).to eq false
      end

      it "returns true if the branch with the provided instance name exists in the git repo" do
        setup_test_repo(name: "test_repo", branches: ["test-branch-1", "test-branch-2"])

        test_branch_1 = Branch.find("test-branch-1")
        test_branch_2 = Branch.find("test-branch-2")
        test_branch_3 = Branch.find("test-branch-3")

        expect(test_branch_1.exists?).to eq true
        expect(test_branch_2.exists?).to eq true
        expect(test_branch_3.exists?).to eq false
      end
    end

    describe "#master?" do
      it "returns true if branch name is 'master', false otherwise" do
        master_branch = Branch.find("master")
        expect(master_branch.master?).to eq true

        other_branch = Branch.find("other")
        expect(other_branch.master?).to eq false
      end
    end

    describe "#development?" do
      it "returns true if branch name is 'development', false otherwise" do
        development_branch = Branch.find("development")
        expect(development_branch.development?).to eq true

        other_branch = Branch.find("other")
        expect(other_branch.development?).to eq false
      end
    end

    describe "#protected?" do
      it "returns true if branch name is in the protected list, false otherwise" do
        development_branch = Branch.find("development")
        expect(development_branch.protected?).to eq true

        master_branch = Branch.find("master")
        expect(master_branch.protected?).to eq true

        other_branch = Branch.find("other")
        expect(other_branch.protected?).to eq false
      end
    end

    describe "#feature?" do
      it "returns the opposite of #protected?" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:protected?).and_return(true)
        expect(random_branch.feature?).to eq false
        expect(random_branch).to receive(:protected?).and_return(false)
        expect(random_branch.feature?).to eq true
      end
    end

    describe "#delete!" do
      it "checks if branch is allowed to be deleted" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:authorize_delete!).and_return(true)
        allow(System).to receive(:call)

        random_branch.delete!
      end

      it "makes a system call for 'branch -d branch-name" do
        random_branch = Branch.find("random")
        allow(random_branch).to receive(:authorize_delete!).and_return(true)
        expect(System).to receive(:call).with("branch -d random")

        random_branch.delete!
      end

      it "allows to change the deletion flag to -D instead of -d" do
        random_branch = Branch.find("random")
        allow(random_branch).to receive(:authorize_delete!).and_return(true)

        expect(System).to receive(:call).with("branch -D random")

        random_branch.delete! force: true

      end

      it "allows deletion of a feature branch" do
        random_branch = Branch.find("random")
        allow(System).to receive(:call)
        expect { random_branch.delete! }.not_to raise_error
      end

      it "doesn't allow deletion of a protected branch" do
        master_branch = Branch.find("master")
        expect { master_branch.delete! }.to raise_error Branch::ProtectedBranchError
      end
    end

    describe "#delete_remote!" do
      it "checks if branch is allowed to be deleted" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:authorize_delete!).and_return(true)
        allow(System).to receive(:call)

        random_branch.delete_remote!
      end

      it "makes a system call for 'push origin :branch-name" do
        random_branch = Branch.find("random")
        allow(random_branch).to receive(:authorize_delete!).and_return(true)
        expect(System).to receive(:call).with("push origin :random")

        random_branch.delete_remote!
      end

      it "allows deletion of a feature branch" do
        random_branch = Branch.find("random")
        allow(System).to receive(:call)
        expect { random_branch.delete_remote! }.not_to raise_error
      end

      it "doesn't allow deletion of a protected branch" do
        master_branch = Branch.find("master")
        expect { master_branch.delete_remote! }.to raise_error Branch::ProtectedBranchError
      end
    end

    describe "#push" do
      it "checks if the branch is public before pushing it" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:ensure_public!).and_return(true)
        allow(System).to receive(:call)

        random_branch.push
      end

      it "makes a system call for 'push origin branch-name:branch-name'" do
        random_branch = Branch.find("random")
        allow(random_branch).to receive(:ensure_public!).and_return(true)
        expect(System).to receive(:call).with("push origin random:random")

        random_branch.push
      end

      it "allows pushing of a public branch" do
        random_branch = Branch.find("random")
        allow(System).to receive(:call)
        expect { random_branch.push }.not_to raise_error
      end

      it "doesn't allow pushing of a private branch" do
        master_branch = Branch.find("random-local")
        expect { master_branch.push }.to raise_error Branch::PrivateBranchError
      end
    end

    describe "#pull" do
      it "makes a system call for 'pull origin branch-name:branch-name'" do
        random_branch = Branch.find("random")
        expect(System).to receive(:call).with("pull origin random:random")
        random_branch.pull
      end
    end

    describe "#checkout" do
      it "makes a system call for 'checkout branch-name'" do
        random_branch = Branch.find("random")
        expect(System).to receive(:call).with("checkout random")
        random_branch.checkout
      end

      it "returns its own instance" do
        random_branch = Branch.find("random")
        allow(System).to receive(:call)
        expect(random_branch.checkout).to eq random_branch
      end
    end

    describe "#authorize_delete!" do
      it "raises a ProtectedBranchError for protected branches" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:protected?).and_return(true)
        expect { random_branch.authorize_delete!}.to raise_error Branch::ProtectedBranchError
      end

      it "doesn't raise an error for unprotected branches" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:protected?).and_return(false)
        expect {random_branch.authorize_delete!}.not_to raise_error
      end
    end

    describe "#message" do
      it "returns the capitalized branch name, where dashes are replaced with spaces" do
        random_branch = Branch.find("random")
        expect(random_branch.message).to eq "Random"
        random_branch = Branch.find("random-branch")
        expect(random_branch.message).to eq "Random branch"
      end
    end

    describe "#private?" do
      it "returns true if branch name ends with '-local'" do
        random_branch = Branch.find("random")
        expect(random_branch.private?).to eq false
        random_branch = Branch.find("random-local")
        expect(random_branch.private?).to eq true
      end
    end

    describe "#hotfix?" do
      it "returns true if branch name starts with 'hotfix-'" do
        random_branch = Branch.find("random")
        expect(random_branch.hotfix?).to eq false
        random_branch = Branch.find("hotfix-random")
        expect(random_branch.hotfix?).to eq true
      end
    end

    describe "#has_pull_request?" do
      it "returns true if #pull_request is not nil, false otherwise" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:pull_request).and_return("something")
        expect(random_branch.has_pull_request?).to eq true
        expect(random_branch).to receive(:pull_request).and_return(nil)
        expect(random_branch.has_pull_request?).to eq false
      end
    end

    describe "#mark_prs_as_awaiting_review" do
      it "calls #label_prs with 'awaiting review'" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:label_prs).with("awaiting review")
        random_branch.mark_prs_as_awaiting_review
      end

      it "throws NoPRError if branch has no pull requests" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:has_pull_request?).and_return(false)
        expect { random_branch.mark_prs_as_awaiting_review }.to raise_error Branch::NoPRError
      end
    end

    describe "#mark_prs_as_hotfix" do
      it "calls #label_prs with 'hotfix'" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:label_prs).with("hotfix")
        random_branch.mark_prs_as_hotfix
      end

      it "throws NoPRError if branch has no pull requests" do
        random_branch = Branch.find("random")
        expect(random_branch).to receive(:has_pull_request?).and_return(false)
        expect { random_branch.mark_prs_as_hotfix }.to raise_error Branch::NoPRError
      end
    end

    describe "#pull_request" do
      it "returns the first item in #pull_requests" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:pull_requests).and_return(["first", "second"])
        expect(random_branch.pull_request).to eq "first"
      end

      it "returns nil if #pull_requests is empty" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:pull_requests).and_return([])
        expect(random_branch.pull_request).to eq nil
      end
    end

    describe "#pull_requests" do
      it "calls 'PullRequest.for_branch'" do
        random_branch = Branch.find("random")
        pull_requests = [ Code::PullRequest.new({}) ]

        expect(PullRequest).to receive(:for_branch).with(random_branch).and_return(pull_requests)
        expect(random_branch.pull_requests).to eq pull_requests
      end
    end

    describe "#pull_request_url" do
      it "returns #pull_request.url" do
        random_branch = Branch.find("random")
        pull_request = Code::PullRequest.new({ html_url: "example.com" })

        expect(random_branch).to receive(:pull_request).and_return(pull_request)
        expect(random_branch.pull_request_url).to eq "example.com"
      end
    end

    describe "#ensure_public!" do
      it "raises error if branch is private" do
        random_branch = Branch.find("random-local")

        expect { random_branch.ensure_public! }.to raise_error Branch::PrivateBranchError
      end

      it "raises no error if branch is public" do
        random_branch = Branch.find("random")

        expect { random_branch.ensure_public! }.not_to raise_error
      end
    end

    describe "#label_prs" do
      it "rases a NoPRError if there are no PRs" do
        random_branch = Branch.find("random")

        expect(random_branch).to receive(:has_pull_request?).and_return(false)
        expect { random_branch.send(:label_prs, "label") }.to raise_error Branch::NoPRError
      end

      it "calls PullRequest#add_label for each pull_request" do
        random_branch = Branch.find("random")

        pull_request_a = Code::PullRequest.new({})
        pull_request_b = Code::PullRequest.new({})

        expect(random_branch).to receive(:pull_requests).and_return([pull_request_a, pull_request_b]).twice

        expect(pull_request_a).to receive(:add_label).with("label")
        expect(pull_request_b).to receive(:add_label).with("label")

        expect { random_branch.send(:label_prs, "label") }.not_to raise_error

      end
    end
  end
end
