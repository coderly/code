require 'code/git'
require 'code/branch'
require 'code/system'
require "code/config"

require_relative '../support/git_extras'

require 'tmpdir'

module Code
  describe Git do

    let(:git) { Git.new }
    let(:repo_path) { @repo_path }

    before(:all) do
      Git.send :include, GitExtras
    end

    before do
      allow(Config).to receive(:master_branch_name).and_return "master"
      allow(Config).to receive(:development_branch_name).and_return "development"

      allow(System).to receive(:puts)
      Git.setup_test_repo
    end

    describe "#search" do

      before do
        allow(System).to receive(:open_in_browser)
      end

      it 'should call System.open_in_browser with the proper url' do
        expect(System).to receive(:open_in_browser).with('https://github.com/testuser/codegit/find/development')
        git.search
      end
    end

    describe "#start" do
      it "should raise an error if branch already exists" do
        existing_branch = Branch.create "existing-branch"

        expect{ git.start "existing-branch" }.to raise_error Git::FeatureExistsError
      end

      it "should checkout the development branch, pull it, then create and switch to a new branch" do
        expect(System).to receive(:call).with("checkout development")
        expect(System).to receive(:call).with("pull origin development:development")
        expect(System).to receive(:call).with("branch new-feature")
        expect(System).to receive(:call).with("checkout new-feature")

        git.start "new-feature"
      end

      it "should not checkout the development branch if already on it" do
        dev_branch = Branch.create "development"
        allow(git).to receive(:current_branch).and_return(dev_branch)
        expect(System).not_to receive(:call).with("checkout development")

        git.start "new-feature"
      end

      it "should stash and unstash if there are uncommitted changes" do
        allow(git).to receive(:uncommitted_changes?).and_return true

        allow(System).to receive(:call).with("checkout development")
        allow(System).to receive(:call).with("pull origin development:development")
        allow(System).to receive(:call).with("branch new-feature")
        allow(System).to receive(:call).with("checkout new-feature")

        expect(System).to receive(:call).with("stash")
        expect(System).to receive(:call).with("stash pop")

        git.start "new-feature"
      end
    end

    describe "#hotfix" do
      it "should raise an error if branch already exists" do
        existing_branch = Branch.create "hotfix-branch"

        expect{ git.hotfix "branch" }.to raise_error Git::FeatureExistsError
      end

      it "should checkout the master branch, pull it, then create and switch to a new branch" do
        some_other_branch = Branch.create "random-branch"

        allow(git).to receive(:current_branch).and_return(some_other_branch)

        expect(System).to receive(:call).with("checkout master")
        expect(System).to receive(:call).with("pull origin master:master")
        expect(System).to receive(:call).with("branch hotfix-branch")
        expect(System).to receive(:call).with("checkout hotfix-branch")

        git.hotfix "branch"
      end

      it "should not checkout the master branch if already on it" do
        # NOTE: the test git repo is on "master" branch to begin
        expect(System).not_to receive(:call).with("checkout master")

        git.hotfix "branch"
      end

      it "should stash and unstash if there are uncommitted changes" do
        allow(git).to receive(:uncommitted_changes?).and_return true

        allow(System).to receive(:call).with("pull origin master:master")
        allow(System).to receive(:call).with("branch hotfix-new-feature")
        allow(System).to receive(:call).with("checkout hotfix-new-feature")

        expect(System).to receive(:call).with("stash")
        expect(System).to receive(:call).with("stash pop")

        git.hotfix "new-feature"
      end
    end

    describe "#switch" do
      it "should switch to the first branch (alphabetically) matching the provided pattern" do
        Branch.create("some-other-branch")
        Branch.create("some-random-branch")

        expect(System).to receive(:call).with("checkout some-other-branch")
        git.switch("some")

        expect(System).to receive(:call).with("checkout some-random-branch")
        git.switch("some", "random")

        expect(System).to receive(:call).with("checkout some-other-branch")
        git.switch("some", "other")

        expect(System).to receive(:call).with("checkout some-other-branch")
        git.switch("some", "branch")
      end

      it "should raise error if no matching branch was found" do
        expect{ git.switch("some") }.to raise_error Git::BranchDoesntExistError
      end
    end

    describe "#finish" do
      it "should switch to development, perform a pull and delete the previous branch" do
        branch = Branch.create("test-branch")
        development_branch = Branch.create("development")
        branch.checkout

        expect(System).to receive(:call).with("checkout development").and_call_original
        expect(System).to receive(:call).with("pull origin development:development")
        expect(System).to receive(:call).with("branch -d test-branch")

        allow(git).to receive(:fetch)

        git.finish
      end
    end

    describe "#publish" do
      it "should raise an error on a protected branch" do
        branch = Branch.create("protected")
        allow(branch).to receive(:protected?).and_return(true)
        allow(git).to receive(:current_branch).and_return(branch)
        allow(git).to receive(:uncommitted_changes?).and_return(false)

        expect{ git.publish }.to raise_error Git::NotOnFeatureBranchError
      end

      it "should raise an error if there are uncommited_changes" do
        branch = Branch.create("test-branch")
        allow(git).to receive(:current_branch).and_return(branch)
        allow(git).to receive(:uncommitted_changes?).and_return(true)

        expect{ git.publish }.to raise_error Git::UncommittedChangesError
      end

      it "should create a PRs against both development and master for a hotfix branch, then label them" do
        branch = Branch.create("hotfix-test")
        allow(git).to receive(:current_branch).and_return(branch)
        allow(git).to receive(:uncommitted_changes?).and_return(false)
        allow(git).to receive(:main_repo).and_return("test_org/test_repo")
        allow(git).to receive(:push)

        expect(System).to receive(:exec).with("hub pull-request -f \"Hotfix test\" -b test_org/test_repo:development -h test_org/test_repo:hotfix-test").and_return("something")
        expect(System).to receive(:exec).with("hub pull-request -f \"Hotfix test\" -b test_org/test_repo:master -h test_org/test_repo:hotfix-test").and_return("something")
        expect(branch).to receive(:mark_prs_as_hotfix)

        git.publish
      end

      it "should create a PR against development for any other feature branch" do
        branch = Branch.create("test-feature")
        allow(git).to receive(:current_branch).and_return(branch)
        allow(git).to receive(:uncommitted_changes?).and_return(false)
        allow(git).to receive(:main_repo).and_return("test_org/test_repo")
        allow(git).to receive(:push)

        allow(System).to receive(:exec).with("git ls-remote --get-url origin").and_call_original
        expect(System).to receive(:exec).with("hub pull-request -f \"Test feature\" -b test_org/test_repo:development -h test_org/test_repo:test-feature").and_return("something")

        git.publish

      end
    end

    describe "#cancel" do
      it "should not do anything if already on development branch" do
        dev_branch = Branch.create "development"

        allow(git).to receive(:current_branch).and_return(dev_branch)

        expect(STDOUT).to receive(:puts).with("Nothing to cancel (already on development)")

        git.cancel
      end

      it "should switch to development, then delete previous branch, with force flag" do
        some_branch = Branch.create "some-branch"
        Branch.create "development"

        allow(git).to receive(:current_branch).and_return(some_branch)

        expect(System).to receive(:call).with("checkout development")
        expect(some_branch).to receive(:delete!).with(force: true)

        git.cancel
      end
    end

    describe "#commit" do
      it "should add all files to the list and commit with the specified message" do
        expect(System).to receive(:call).with("add -A")
        expect(System).to receive(:call).with("commit -m \"test message\"")

        git.commit "test message"
      end
    end

    describe "#push" do
      it "should push to origin" do
        expect(System).to receive(:call).with("push origin master:master")
        git.push
      end
    end

    describe "#prune_remote_branches" do
      it "should call the appropriate git command" do
        expect(System).to receive(:call).with("remote prune origin")

        git.prune_remote_branches
      end
    end
  end
end
