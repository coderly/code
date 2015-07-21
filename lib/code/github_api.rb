require "octokit"
require "code/repository"
require "securerandom"
require "io/console"

module Code

  class GitHubAPI

    def authorization_note
      "CoderlyCode-" + SecureRandom.uuid
    end

    def initialize(repository: Repository.current)
      @repository = repository
    end

    def ensure_authorized
      if not authorized?
        username = prompt 'GitHub username'
        password = prompt_password 'GitHub password'

        authorize(username: username, password: password)
      end
    end

    def authorize(username:, password:)
      client = self.octokit_client_instance_from_basic_auth(username: username, password: password)

      token = client.create_authorization(scopes: ["repo"], note: authorization_note)[:token]

      puts "Successfully authorized with token #{token}"
      self.authorization_token = token
    end

    def pull_requests_for_branch(branch)
      client = self.octokit_client_instance_from_token
      client.pull_requests(current_repo_slug, head: "#{current_organization}:#{branch.name}")
    end

    def octokit_client_instance_from_token
      client = Octokit::Client.new access_token: authorization_token
    end

    def octokit_client_instance_from_basic_auth(username:, password:)
      client = Octokit::Client.new login: username, password: password
    end

    def label_pr(pull_request, label)
      add_label_to_pr(pull_request.number, label)
    end

    def authorized?
      !authorization_token.empty?
    end

    private

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

    def authorization_token
      token = System.result('git config --get oauth.token')
      token
    end

    def authorization_token=(token)
      System.result("git config --global oauth.token #{token}")
    end

    def prompt(prompt_text)
      print prompt_text + ':'
      input = gets
      input.strip
    end

    def prompt_password(prompt_text)
      print prompt_text + ':'
      input = STDIN.noecho(&:gets)
      puts
      input.strip
    end
  end
end
