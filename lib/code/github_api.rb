require "octokit"

module Code

  class GitHubAPI

    AUTHORIZATION_NOTE = "Code gem authorization token"

    def self.authorization_token=(token)
      System.call("config --global oauth.token #{token}")
    end

    def self.octokit_client_instance_from_basic_auth(username:, password:)
      client = Octokit::Client.new login: username, password: password
    end

    def self.authorize(username:, password:)
      client = self.octokit_client_instance_from_basic_auth(username: username, password: password)

      authorization = client.authorizations.detect { |auth| auth[:note] == AUTHORIZATION_NOTE}
      if authorization
        self.authorization_token = authorization[:token]
      else
        self.authorization_token = client.create_authorization(scopes: ["repo"], note: AUTHORIZATION_NOTE)[:token]
      end
    end

    attr_accessor :origin_url
    attr_accessor :authorization_token

    def initialize
      @origin_url = System.call("config --get remote.origin.url")
      @authorization_token = System.call('config --get oauth.token')
    end

    def current_branch_pr_url
      client = octokit_client_instance_from_token
      client.pull_requests(current_repo, head: "#{current_organization}:#{Branch.current}")[0][:html_url]
    end

    def current_branch_pr?
      client = self.octokit_client_instance_from_token
      client.pull_requests(current_repo, head: "#{current_organization}:#{Branch.current}").any?
    end

    def current_organization
      @origin_url.split('/')[-2]
    end

    def current_repo_name
      @origin_url.split("/")[-1].split('.')[0]
    end

    def current_repo
      "#{current_organization}/#{current_repo_name}"
    end

    def octokit_client_instance_from_token
      client = Octokit::Client.new access_token: authorization_token
    end
  end
end