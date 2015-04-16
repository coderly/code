module Code

  class Repository

    def self.current_repository_url
      System.result("git config --get remote.origin.url")
    end

    def self.from_current_repository_url
      new(url: Repository.current_repository_url)
    end

    def initialize(url:)
      @url = url
    end

    def organization
      organization_name = @url.split("/")[-2]

      possible_prefix = "git@github.com:"
      organization_name.sub!(possible_prefix,"")

      organization_name
    end

    def name
      repo_name_with_extension = @url.split("/").last
      repo_name_without_extension = repo_name_with_extension.sub(".git", "")

      repo_name_without_extension
    end

    def slug
      "#{organization}/#{name}"
    end

  end

end