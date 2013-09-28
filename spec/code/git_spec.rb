require 'code/git'
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
      git.init
    end

    describe 'current_branch' do
      let(:branch) { git.current_branch }
      subject { branch }

      its(:name) { should eq 'master' }
    end

  end
end