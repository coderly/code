require 'uri'

require 'code/branch'
require 'code/system'

module Code

  class Git

    def path
      Dir.pwd
    end

    def start(feature)
      ensure_feature_missing! feature

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
      abort 'Must be on a feature branch to publish your code' unless current_branch.feature?

      ensure_clean_slate!

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

      delete_branch branch
    end

    def files_changed?
      System.result('git diff --name-status') != ''
    end

    def checkout(branch)
      System.call "checkout #{branch}"
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

    def ensure_safe_branch!(branch)
      error "branch #{branch} is protected" if protected_branch? branch
    end

    def ensure_feature_missing!(feature)
      error "The #{feature} feature already exists" if feature_exists?(feature)
    end

    def ensure_clean_slate!
      if files_changed?
        error 'Please stash or commit your code'
      end
    end

  end

end
