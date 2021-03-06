require "code/repository"
require "code/system"

require "octokit"
require "securerandom"

module Code

  class GitHubAPI

    def initialize(repository: Repository.current)
      @repository = repository
    end

    def ensure_authorized
      if not authorized?
        username = System.prompt 'GitHub username'
        password = System.prompt_hidden 'GitHub password'

        authorize(username: username, password: password)
      end
    end

    def pull_requests_for_branch(branch)
      client = octokit_client_instance_from_token
      client.pull_requests(current_repo_slug, head: "#{current_organization}:#{branch.name}")
    end

    def label_pr(pull_request, label)
      add_label_to_pr(pull_request.number, label)
    end

    private

    def octokit_client_instance_from_token
      client = Octokit::Client.new access_token: authorization_token
    end

    def octokit_client_instance_from_basic_auth(username:, password:)
      client = Octokit::Client.new login: username, password: password
    end

    def create_token(client)
      client.create_authorization(scopes: ["repo"], note: authorization_note)[:token]
    end

    def current_organization
      @repository.organization
    end

    def current_repo_slug
      @repository.slug
    end

    def current_branch
      Branch.current
    end

    def add_label_to_pr(number, label)
      octokit_client_instance_from_token.add_labels_to_an_issue(current_repo_slug, number, [label])
    end

    def authorize(username:, password:)
      client = octokit_client_instance_from_basic_auth(username: username, password: password)
      token = create_token(client)
      self.authorization_token = token
    end

    def authorized?
      !authorization_token.empty?
    end

    def authorization_token
      token = System.result('git config --get oauth.token')
      token
    end

    def authorization_token=(token)
      System.result("git config --global oauth.token #{token}")
    end

    def authorization_note
      "CoderlyCode-" + SecureRandom.uuid
    end

  end
end
