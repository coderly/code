require "octokit"

module Code

  class GitHubAPI

    NoAuthTokenError = Class.new(StandardError)

    AUTHORIZATION_NOTE = "Code gem authorization token"

    def authorize(username:, password:)
      client = self.octokit_client_instance_from_basic_auth(username: username, password: password)

      authorization = client.authorizations.detect { |auth| auth[:note] == AUTHORIZATION_NOTE }

      if authorization
        token = authorization[:token]
      else
        token = client.create_authorization(scopes: ["repo"], note: AUTHORIZATION_NOTE)[:token]
      end

      puts "Successfully authorized with token #{token}"
      self.authorization_token = token
    end

    def current_branch_pr_url
      client = octokit_client_instance_from_token
      client.pull_requests(current_repo, head: "#{current_organization}:#{current_branch}")[0][:html_url]
    end

    def current_branch_pr?
      client = self.octokit_client_instance_from_token
      client.pull_requests(current_repo, head: "#{current_organization}:#{current_branch}").any?
    end

    def octokit_client_instance_from_token
      client = Octokit::Client.new access_token: authorization_token
    end

    def octokit_client_instance_from_basic_auth(username:, password:)
      client = Octokit::Client.new login: username, password: password
    end

    def origin_url
      System.result("git config --get remote.origin.url")
    end

    def current_organization
      origin_url.split('/')[-2]
    end

    def current_repo_name
      origin_url.split("/")[-1].split('.')[0]
    end

    def current_repo
      "#{current_organization}/#{current_repo_name}"
    end

    def current_branch
      Branch.current
    end

    def authorization_token
      token = System.result('git config --get oauth.token')
      raise NoAuthTokenError, "Couldn't retrieve an authorization token. Make sure you authorize through 'code authorize --username {username} --password {password}' first" if System.command_failed?
      token
    end

    def authorization_token=(token)
      System.result("git config --global oauth.token #{token}")
    end
  end
end