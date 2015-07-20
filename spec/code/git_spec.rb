require 'code/git'
require 'code/branch'
require 'code/system'

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
      allow(System).to receive(:puts)
      Git.setup_test_repo
    end

    describe 'current_branch' do
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

    describe 'search' do

      before do
        allow(System).to receive(:open_in_browser)
      end

      it 'should call System.open_in_browser with the proper url' do
        expect(System).to receive(:open_in_browser).with('https://github.com/testuser/codegit/find/development')

        git = Git.new

        git.search
      end
    end

  end
end
