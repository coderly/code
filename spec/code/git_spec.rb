require 'code/git'
require 'code/system'

require 'tmpdir'

module Code
  describe Git do

    let(:git) { Git.new }
    let(:repo_path) { @repo_path }

    before do
      System.stub(:puts)

      @repo_path = Dir.mktmpdir
      Dir.chdir repo_path
      System.exec 'git init'
    end

    describe 'current_branch' do
      let(:branch) { git.current_branch }
      subject { branch }

      its(:name) { should eq 'master' }
    end

  end
end