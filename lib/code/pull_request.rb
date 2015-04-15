require 'code/github_api'

module Code
  class PullRequest

    def initialize(pull_request_info)
      @pull_request_info = pull_request_info
    end

    def self.for_branch(branch)
      fetch_prs_for_branch(branch).map do |pull_request_info|
        new(pull_request_info)
      end
    end

    def url
      pull_request_info[:html_url]
    end

    def number
      pull_request_info[:number]
    end

    def add_label(label)
      github_api.label_pr(self, label)
    end

    private

    attr_reader :pull_request_info

    def github_api
      @github_api ||= GitHubAPI.new
    end

    def self.fetch_prs_for_branch(branch)
      github_api.prs_for_branch(branch)
    end
    
    # I need a github api instance to create instances
    # and also need an api instance once the PullRequest instance is created
    # I tried to solve this problem with modules by extending on the two places
    # but it seems like overkilling it, I'll duplicate it for now.
    def self.github_api
      @github_api ||= GitHubAPI.new
    end

  end
end