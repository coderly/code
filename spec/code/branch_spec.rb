require "code/branch"
require "code/system"
require "code/pull_request"
require "code/config"

module Code
  describe Branch do

    before(:all) do
      Branch.send :include, GitExtras
    end

    before do
      allow(Config).to receive(:get_master_branch_name).and_return "master"
      allow(Config).to receive(:get_development_branch_name).and_return "development"
      allow(System).to receive(:puts)
      Branch.setup_test_repo
    end

    describe "self.all_names" do

      before do
        Branch.add_branches(["test-branch-1", "test-branch-2"])
      end

      it "returns names of all branches in the repo as strings" do
        branch_names = Branch.all_names

        expect(branch_names.length).to eq 3
        expect(branch_names[0]).to eq "master"
        expect(branch_names[1]).to eq "test-branch-1"
        expect(branch_names[2]).to eq "test-branch-2"
      end
    end

    describe "self.all" do

      before do
        Branch.add_branches(["test-branch-1", "test-branch-2"])
      end

      it "returns Branch instances for all branches in the repo" do

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

    describe "self.matching" do

      before do
        Branch.add_branches(["test-branch-1", "test-branch-2"])
      end

      it "returns the first branch that matches the patterns" do
        expect(Branch.matching('test', 'branch').name).to eq 'test-branch-1'
        expect(Branch.matching('test', '2').name).to eq 'test-branch-2'
      end
    end

    describe "self.exists?" do

      before do
        Branch.add_branches(["test-branch-1", "test-branch-2"])
      end

      it "returns true for a localy known branch, false otherwise" do
        expect(Branch.exists? "master").to eq true
        expect(Branch.exists? "test-branch-1").to eq true
        expect(Branch.exists? "test-branch-2").to eq true
        expect(Branch.exists? "test-branch-3").to eq false
      end
    end

    describe "self.current" do
      let(:branch) { Branch.current }

      subject { branch }

      it "should currently be on the master branch" do
        expect(branch.name).to eq 'master'
      end

      context "when creating a new branch" do

        before do
          Branch.create "test_branch"
        end

        it "should have the right branches" do
          expect(Branch.all.count).to eq 2
        end

        it "should have created the branch" do
          expect(Branch.new("test_branch")).to exist
        end

        context "when deleting a branch" do
          before do
            Branch.matching("test_branch").delete!
          end

          it "should only have one branch left" do
            expect(Branch.all.count).to eq 1
          end

          it "should have deleted the branch" do
            expect(Branch.new("test_branch")).to_not exist
          end
        end

        context "when checking out a branch" do
          before do
            Branch.matching('test_branch').checkout
          end

          it "should have changed the branch" do
            expect(Branch.current.name).to eq 'test_branch'
          end
        end
      end

      context "when trying to delete a protected branch" do

        before do
          Branch.create "development"
        end

        it "should now be allowed" do
          expect { Branch.matching("development").delete! }.to raise_error Branch::ProtectedBranchError
        end
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

        branch = Branch.create "test_branch"

        expect(branch).to be_a Branch
        expect(branch.name).to eq "test_branch"
      end
    end

    describe "self.find" do
      it "creates a new Branch instance with specified name, but makes no System.call" do
        expect(System).not_to receive(:call).with("branch test_branch")

        branch = Branch.find "test_branch"

        expect(branch).to be_a Branch
        expect(branch.name).to eq "test_branch"
      end
    end

    describe "equality comparer" do
      it "compares by branch name" do
        branch_a = Branch.new "branch-a"
        branch_b = Branch.new "branch-b"
        other_branch_a = Branch.new "branch-a"

        expect(branch_a == branch_b).to eq false
        expect(branch_a == other_branch_a).to eq true
        expect(branch_b == other_branch_a).to eq false
      end
    end

    describe "#matches?" do
      it "returns true if the branch name matches all the patterns" do
        branch = Branch.new "test-branch"

        expect(branch.matches? "test").to eq true
        expect(branch.matches? "test", "branch").to eq true
        expect(branch.matches? "branch").to eq true
        expect(branch.matches? "test-branch").to eq true
      end

      it "returns false if the branch name matches some or none of the patterns" do
        branch = Branch.new "test-branch"

        expect(branch.matches? "test_branch").to eq false
        expect(branch.matches? "tst").to eq false
        expect(branch.matches? "tst", "test").to eq false
      end
    end

    describe "#exists" do

      before do
        Branch.add_branches(["test-branch-1", "test-branch-2"])
      end

      it "calls System.result and returns the result" do
        test_branch_1 = Branch.new "test-branch-1"

        expect(System).to receive(:result).with("git show-ref refs/heads/test-branch-1").and_return("something")
        expect(test_branch_1.exists?).to eq true


        expect(System).to receive(:result).with("git show-ref refs/heads/test-branch-1").and_return("")
        expect(test_branch_1.exists?).to eq false
      end

      it "returns true if the branch with the provided instance name exists in the git repo" do
        test_branch_1 = Branch.new "test-branch-1"
        test_branch_2 = Branch.new "test-branch-2"
        test_branch_3 = Branch.new "test-branch-3"

        expect(test_branch_1.exists?).to eq true
        expect(test_branch_2.exists?).to eq true
        expect(test_branch_3.exists?).to eq false
      end
    end

    describe "#master?" do
      it "returns true if branch name is 'master', false otherwise" do
        master_branch = Branch.new "master"
        expect(master_branch.master?).to eq true

        other_branch = Branch.new "other"
        expect(other_branch.master?).to eq false
      end
    end

    describe "#development?" do
      it "returns true if branch name is 'development', false otherwise" do
        development_branch = Branch.new "development"
        expect(development_branch.development?).to eq true

        other_branch = Branch.new "other"
        expect(other_branch.development?).to eq false
      end
    end

    describe "#protected?" do
      it "returns true if branch name is in the protected list, false otherwise" do
        development_branch = Branch.new "development"
        expect(development_branch.protected?).to eq true

        master_branch = Branch.new "master"
        expect(master_branch.protected?).to eq true

        other_branch = Branch.new "other"
        expect(other_branch.protected?).to eq false
      end
    end

    describe "#feature?" do
      it "returns the opposite of #protected?" do
        random_branch = Branch.new "random"
        expect(random_branch).to receive(:protected?).and_return(true)
        expect(random_branch.feature?).to eq false
        expect(random_branch).to receive(:protected?).and_return(false)
        expect(random_branch.feature?).to eq true
      end
    end

    describe "#delete!" do
      it "checks if branch is allowed to be deleted" do
        random_branch = Branch.new "random"

        expect(random_branch).to receive(:authorize_delete!).and_return(true)
        allow(System).to receive(:call)

        random_branch.delete!
      end

      it "makes a system call for 'branch -d branch-name" do
        random_branch = Branch.new "random"
        allow(random_branch).to receive(:authorize_delete!).and_return(true)
        expect(System).to receive(:call).with("branch -d random")

        random_branch.delete!
      end

      it "allows to change the deletion flag to -D instead of -d" do
        random_branch = Branch.new "random"
        allow(random_branch).to receive(:authorize_delete!).and_return(true)

        expect(System).to receive(:call).with("branch -D random")

        random_branch.delete! force: true

      end

      it "allows deletion of a feature branch" do
        random_branch = Branch.new "random"
        allow(System).to receive(:call)
        expect { random_branch.delete! }.not_to raise_error
      end

      it "doesn't allow deletion of a protected branch" do
        master_branch = Branch.new "master"
        expect { master_branch.delete! }.to raise_error Branch::ProtectedBranchError
      end
    end

    describe "#delete_remote!" do
      it "checks if branch is allowed to be deleted" do
        random_branch = Branch.new "random"

        expect(random_branch).to receive(:authorize_delete!).and_return(true)
        allow(System).to receive(:call)

        random_branch.delete_remote!
      end

      it "makes a system call for 'push origin :branch-name" do
        random_branch = Branch.new "random"
        allow(random_branch).to receive(:authorize_delete!).and_return(true)
        expect(System).to receive(:call).with("push origin :random")

        random_branch.delete_remote!
      end

      it "allows deletion of a feature branch" do
        random_branch = Branch.new "random"
        allow(System).to receive(:call)
        expect { random_branch.delete_remote! }.not_to raise_error
      end

      it "doesn't allow deletion of a protected branch" do
        master_branch = Branch.new "master"
        expect { master_branch.delete_remote! }.to raise_error Branch::ProtectedBranchError
      end
    end

    describe "#push" do
      it "makes a system call for 'push origin branch-name:branch-name'" do
        random_branch = Branch.new "random"
        allow(random_branch).to receive(:ensure_public!).and_return(true)
        expect(System).to receive(:call).with("push origin random:random")

        random_branch.push
      end

      it "allows pushing of a public branch" do
        random_branch = Branch.new "random"
        allow(System).to receive(:call).with("push origin random:random")
        expect { random_branch.push }.not_to raise_error
      end

      it "doesn't allow pushing of a private branch" do
        master_branch = Branch.new "random-local"
        expect { master_branch.push }.to raise_error Branch::PrivateBranchError
      end
    end

    describe "#pull" do
      it "makes a system call for 'pull origin branch-name:branch-name'" do
        random_branch = Branch.new "random"
        expect(System).to receive(:call).with("pull origin random:random")
        random_branch.pull
      end
    end

    describe "#checkout" do
      it "makes a system call for 'checkout branch-name'" do
        random_branch = Branch.new "random"
        expect(System).to receive(:call).with("checkout random")
        random_branch.checkout
      end

      it "returns its own instance" do
        random_branch = Branch.new "random"
        allow(System).to receive(:call)
        expect(random_branch.checkout).to eq random_branch
      end
    end

    describe "#message" do
      it "returns the capitalized branch name, where dashes are replaced with spaces" do
        random_branch = Branch.new "random"
        expect(random_branch.message).to eq "Random"
        random_branch = Branch.new "random-branch"
        expect(random_branch.message).to eq "Random branch"
      end
    end

    describe "#private?" do
      it "returns true if branch name ends with '-local'" do
        random_branch = Branch.new "random"
        expect(random_branch.private?).to eq false
        random_branch = Branch.new "random-local"
        expect(random_branch.private?).to eq true
      end
    end

    describe "#hotfix?" do
      it "returns true if branch name starts with 'hotfix-'" do
        random_branch = Branch.new "random"
        expect(random_branch.hotfix?).to eq false
        random_branch = Branch.new "hotfix-random"
        expect(random_branch.hotfix?).to eq true
      end
    end

    describe "#has_pull_request?" do
      it "returns true if the branch has any pull requests, false otherwise" do
        random_branch_1 = Branch.new "random_1"
        pull_request_1 = PullRequest.new(pull_request_info: { html_url: "example.com" })
        pull_request_2 = PullRequest.new(pull_request_info: { html_url: "example2.com" })

        expect(PullRequest).to receive(:for_branch).with(random_branch_1).and_return([pull_request_1, pull_request_2])
        expect(random_branch_1.has_pull_request?).to eq true

        random_branch_2 = Branch.new "random_2"
        expect(PullRequest).to receive(:for_branch).with(random_branch_2).and_return([])
        expect(random_branch_2.has_pull_request?).to eq false
      end
    end

    describe "#mark_prs_as_awaiting_review" do
      it "calls #label_prs with 'awaiting review'" do
        random_branch = Branch.new "random"
        expect(random_branch).to receive(:label_prs).with("awaiting review")
        random_branch.mark_prs_as_awaiting_review
      end

      it "throws NoPRError if branch has no pull requests" do
        random_branch = Branch.new "random"
        expect(random_branch).to receive(:has_pull_request?).and_return(false)
        expect { random_branch.mark_prs_as_awaiting_review }.to raise_error Branch::NoPRError
      end
    end

    describe "#mark_prs_as_hotfix" do
      it "calls #label_prs with 'hotfix'" do
        random_branch = Branch.new "random"
        expect(random_branch).to receive(:label_prs).with("hotfix")
        random_branch.mark_prs_as_hotfix
      end

      it "throws NoPRError if branch has no pull requests" do
        random_branch = Branch.new "random"
        expect(random_branch).to receive(:has_pull_request?).and_return(false)
        expect { random_branch.mark_prs_as_hotfix }.to raise_error Branch::NoPRError
      end
    end

    describe "#pull_request_url" do
      it "returns the URL of the first pull request" do
        random_branch = Branch.new "random"
        pull_request_1 = PullRequest.new(pull_request_info: { html_url: "example.com" })
        pull_request_2 = PullRequest.new(pull_request_info: { html_url: "example2.com" })

        expect(PullRequest).to receive(:for_branch).and_return([pull_request_1, pull_request_2])

        expect(random_branch.pull_request_url).to eq "example.com"
      end
    end
  end
end
