require 'uri'

require 'code/branch'
require 'code/system'

module Code

  class Git

    NotOnFeatureBranchError = Class.new(StandardError)
    UncommittedChangesError = Class.new(StandardError)
    FeatureExistsError = Class.new(StandardError)

    def path
      Dir.pwd
    end

    def start(feature)
      raise FeatureExistsError, "Feature #{feature} already exists" if Branch.exists?(feature)

      development_branch.checkout unless current_branch.main?
      development_branch.pull

      create_branch feature
      checkout feature
    end

    def switch(*patterns)
      Branch.matching(*patterns).checkout
    end

    def cancel
      if current_branch.main?
        puts "Nothing to cancel (already on #{main_branch})"
      else
        previous_branch = current_branch
        checkout main_branch
        previous_branch.delete!(force: true)
      end
    end

    def publish(message = '')
      raise NotOnFeatureBranchError, 'Must be on a feature branch to publish your code' unless current_branch.feature?
      raise UncommittedChangesError, 'You have uncommitted changes' if uncommitted_changes?

      current_branch.push

      System.open_in_browser pull_request(message)
    end

    def push(branch_name)

      current_branch.push
    end

    def pull_request(message = '')
      message = current_branch if message.empty?
      command = "hub pull-request -f \"#{message}\" -b #{main_repo}:development -h #{main_repo}:#{current_branch}"
      System.exec(command).strip
    end

    def compare_in_browser(branch)
      System.exec "hub compare #{branch}"
    end

    def finish
      branch = current_branch

      main_branch.checkout
      fetch
      main_branch.pull

      branch.delete
    end

    def uncommitted_changes?
      System.result('git diff --name-status') != ''
    end

    def checkout(branch_name)
      Branch.matching(branch_name).checkout
    end

    def fetch
      System.call 'fetch'
    end

    def current_branch
      Branch.current
    end

    def development_branch
      Branch.development
    end

    def main_repo
      main_repo_url[/:(\w+)\//,1]
    end

    def main_repo_url
      repo_url 'origin'
    end

    def repo_url(name)
      System.result("git ls-remote --get-url #{name}")
    end

  end

end
