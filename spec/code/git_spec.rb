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
      System.stub(:puts)
      Git.setup_test_repo
    end

    describe 'current_branch' do
      let(:branch) { git.current_branch }
      subject { branch }

      its(:name) { should eq 'master' }

      context 'when creating a new branch' do

        before do
          Branch.create 'test_branch'
        end

        it 'should have the right branches' do
          Branch.all.count.should eq 2
        end

        context 'when deleting a branch' do
          before do
            Branch.matching('test_branch').delete!
          end

          it 'should only have one branch left' do
            Branch.all.count.should eq 1
          end
        end

        context 'when checking out a branch' do
          before do
            Branch.matching('test_branch').checkout
          end

          it 'should have changed the branch' do
            Branch.current.name.should eq 'test_branch'
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

  end
end