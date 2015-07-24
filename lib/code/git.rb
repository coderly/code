require 'uri'

require 'code/branch'
require 'code/system'

module Code

  class Git

    NotOnFeatureBranchError = Class.new(StandardError)
    UncommittedChangesError = Class.new(StandardError)
    FeatureExistsError = Class.new(StandardError)

    def initialize()
    end

    def start(feature)
      raise FeatureExistsError, "Branch #{feature} already exists" if Branch.exists?(feature)

      with_stash do
        development_branch.checkout unless current_branch.development?
        development_branch.pull

        Branch.create(feature).checkout
      end
    end

    def hotfix(name)
      name = "hotfix-#{name}"
      raise FeatureExistsError, "Branch #{name} already exists" if Branch.exists?(name)

      with_stash do
        master_branch.checkout unless current_branch.master?
        master_branch.pull

        Branch.create(name).checkout
      end
    end

    def switch(*patterns)
      Branch.matching(*patterns).checkout
    end

    def cancel
      if current_branch.development?
        puts "Nothing to cancel (already on #{development_branch})"
      else
        previous_branch = current_branch
        checkout development_branch
        previous_branch.delete!(force: true)
      end
    end

    # NOT used anywhere at the moment. Did we loose track of a supported command?
    def commit(message)
      System.call 'add -A'
      System.call "commit -m \"#{message}\""
    end

    def publish(base: nil, message: '')
      raise NotOnFeatureBranchError, 'Must be on a feature branch to publish your code' unless current_branch.feature?
      raise UncommittedChangesError, 'You have uncommitted changes' if uncommitted_changes?
      push
      create_prs_for(base, message)
    end

    def finish
      branch = current_branch

      development_branch.checkout
      fetch
      development_branch.pull

      branch.delete!
    end

    def push
      current_branch.push
    end

    def search
      System.open_in_browser "https://github.com/#{current_repo_slug}/find/development"
    end

    # NOT used anywhere at the moment. Did we loose track of a supported command?
    def compare_in_browser(branch)
      System.exec "hub compare #{branch}"
    end

    def prune_remote_branches
      System.call 'remote prune origin'
    end

    private

    def stash
      System.call('stash')
    end

    def unstash
      System.call('stash pop')
    end

    def with_stash
      if uncommitted_changes?
        stash
        yield
        unstash
      else
        yield
      end
    end

    def create_prs_for(base, message)
      if current_branch.hotfix?
        create_hotfix_prs(message)
      else
        create_feature_pr(base, message)
      end
    end

    def pull_request(base:, message: '')
      base = development_branch unless base
      message = current_branch.message if message.empty?
      command = "hub pull-request -f \"#{message}\" -b #{main_repo}:#{base} -h #{main_repo}:#{current_branch}"
      System.exec(command).strip
    end

    def create_feature_pr(base, message)
      System.open_in_browser pull_request(base: base, message: message)
    end

    def create_hotfix_prs(message)
      System.open_in_browser pull_request(base: master_branch, message: message)
      System.open_in_browser pull_request(base: development_branch, message: message)
      current_branch.mark_prs_as_hotfix
    end

    def uncommitted_changes?
      System.result('git status --porcelain') != ''
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

    def master_branch
      Branch.master
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

    def current_repo_slug
      Repository.current.slug
    end

  end

end
