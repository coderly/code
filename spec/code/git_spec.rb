require 'code/git'
require 'code/branch'
require 'code/system'

require_relative '../support/git_extras'

require 'tmpdir'

module Code
  describe Git do

    let(:github_api) { GitHubAPI.new(repository: Git.test_repo_origin) }
    let(:git) { Git.new(github_api: github_api) }
    let(:repo_path) { @repo_path }

    before(:all) do
      Git.send :include, GitExtras
    end

    before do
      allow(System).to receive(:puts)
      Git.setup_test_repo
    end

    describe "current_branch" do
      let(:branch) { git.current_branch }

      subject { branch }

      it 'should currently be on the master branch' do
        expect(branch.name).to eq 'master'
      end

      context 'when creating a new branch' do

        before do
          Branch.create 'test_branch'
        end

        it 'should have the right branches' do
          expect(Branch.all.count).to eq 2
        end

        it 'should have created the branch' do
          expect(Branch.new('test_branch')).to exist
        end

        context 'when deleting a branch' do
          before do
            Branch.matching('test_branch').delete!
          end

          it 'should only have one branch left' do
            expect(Branch.all.count).to eq 1
          end

          it 'should have deleted the branch' do
            expect(Branch.new('test_branch')).to_not exist
          end
        end

        context 'when checking out a branch' do
          before do
            Branch.matching('test_branch').checkout
          end

          it 'should have changed the branch' do
            expect(Branch.current.name).to eq 'test_branch'
          end
        end

      end

      context 'when trying to delete a protected branch' do

        before do
          Branch.create 'development'
        end

        it 'should now be allowed' do
          expect { Branch.matching('development').delete! }.to raise_error Branch::ProtectedBranchError
        end

      end

    end

    describe "search" do

      before do
        allow(System).to receive(:open_in_browser)
      end

      it 'should call System.open_in_browser with the proper url' do
        expect(System).to receive(:open_in_browser).with('https://github.com/testuser/codegit/find/development')
        git.search
      end
    end

    describe "#repo_url" do
      it "should use the 'git ls-remote' subcommand to get the origin url" do
        expect(System).to receive(:result).with("git ls-remote --get-url origin").and_call_original
        expect(git.repo_url "origin").to eq "https:/github.com/testuser/codegit"
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
        # NOTE: the default git repo is on "master" branch to begin
        expect(System).not_to receive(:call).with("checkout master")

        git.hotfix "branch"
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

        allow(System).to receive(:opent_in_browser).twice

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

        allow(System).to receive(:opent_in_browser).twice

        allow(System).to receive(:exec).with("git ls-remote --get-url origin").and_call_original
        expect(System).to receive(:exec).with("hub pull-request -f \"Test feature\" -b test_org/test_repo:development -h test_org/test_repo:test-feature").and_return("something")

        git.publish

      end
    end

  end
end
