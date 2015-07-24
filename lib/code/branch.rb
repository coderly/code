require 'code/pull_request'

module Code

  class Branch

    ProtectedBranchError = Class.new(StandardError)
    PrivateBranchError = Class.new(StandardError)
    NoPRError = Class.new(StandardError)


    MASTER_BRANCH_NAME = 'master'
    DEVELOPMENT_BRANCH_NAME = 'development'
    PROTECTED_BRANCH_NAMES = %w{master development}

    def self.all_names
      System.result('git branch').strip.lines.map { |line| line.gsub(/\s|\*/, '') }
    end

    def self.all
      all_names.map { |name| new(name) }
    end


    # TODO: This should probably be moved to another class or module.
    # An identical method is used in match_scorer/base
    def self.coerce_patterns(*patterns)
      patterns.flatten.join(' ').split(' ')
    end

    private_class_method :coerce_patterns

    def self.matching(*patterns)
      patterns = coerce_patterns(patterns)
      all.find { |b| b.matches? *patterns }
    end

    def self.exists?(branch_name)
      new(branch_name).exists?
    end

    def self.merged
      clean_branch = lambda { |o| o.gsub('*', '').strip }
      lines = System.result('git branch --merged development')
      branch_names = lines.split("\n").map(&clean_branch)
      branch_names = branch_names - ['development', 'master']
      branch_names.map { |name| new(name) }
    end

    def self.current
      name = System.result('git symbolic-ref HEAD').split('/')[-1]
      new(name)
    end

    def self.development
      new DEVELOPMENT_BRANCH_NAME
    end

    def self.master
      new MASTER_BRANCH_NAME
    end

    def self.create(branch_name)
      System.call "branch #{branch_name}"
      Branch.new(branch_name)
    end

    def self.find(branch_name)
      new(branch_name)
    end

    def initialize(name)
      @name = name
    end

    def ==(branch)
      name == branch.name
    end

    def matches? *patterns
      patterns.all? { |p| name.downcase.include? p.downcase }
    end

    def exists?
      System.result("git show-ref refs/heads/#{name}") != ''
    end

    def development?
      name == DEVELOPMENT_BRANCH_NAME
    end

    def master?
      name == MASTER_BRANCH_NAME
    end

    def protected?
      PROTECTED_BRANCH_NAMES.include? name
    end

    def feature?
      not protected?
    end

    def delete!(force: false)
      authorize_delete!

      flag = force ? '-D' : '-d'
      System.call "branch #{flag} #{name}"
    end

    def delete_remote!
      authorize_delete!

      System.call "push origin :#{name}"
    end

    def push
      ensure_public!
      System.call "push origin #{name}:#{name}"
    end

    def pull
      System.call "pull origin #{name}:#{name}"
    end

    def checkout
      System.call "checkout #{name}"
      self
    end

    def message
      name.gsub('-', ' ').capitalize
    end

    def private?
      !! name.match(/-local$/)
    end

    def hotfix?
      !! name.match(/^hotfix-/)
    end

    def has_pull_request?
      !pull_request.nil?
    end

    def mark_prs_as_awaiting_review
      label_prs("awaiting review")
    end

    def mark_prs_as_hotfix
      label_prs('hotfix')
    end

    def pull_request_url
      # This could be a delegate, but it seems easier to read just by
      # calling it.
      pull_request.url
    end

    attr_reader :name
    alias_method :to_s, :name

    private

    def label_prs(label)
      raise NoPRError, "There is no PR for the this branch" unless has_pull_request?

      pull_requests.each do |pr|
        pr.add_label(label)
      end
    end

    def authorize_delete!
      raise ProtectedBranchError, "The #{name} branch is protected" if protected?
    end

    def pull_request
      pull_requests.first
    end

    def pull_requests
      @pull_request ||= PullRequest.for_branch(self)
    end

    def ensure_public!
      raise PrivateBranchError, "#{name} is a private branch" if private?
    end
  end
end
