module Code

  class Branch

    ProtectedBranchError = Class.new(StandardError)

    DEVELOPMENT_BRANCH_NAME = 'development'
    PROTECTED_BRANCH_NAMES = %w{master development}

    def self.all_names
      System.result('git branch').strip.lines.map { |line| line.gsub(/\s|\*/, '') }
    end

    def self.all
      all_names.map { |name| new(name) }
    end

    def self.matching(*patterns)
      all.find { |b| b.matches? *patterns }
    end

    def self.exists?(branch_name)
      new(branch_name).exists?
    end

    def self.current
      name = System.result('git symbolic-ref HEAD').split('/')[-1]
      new(name)
    end

    def self.development
      new DEVELOPMENT_BRANCH_NAME
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

    def exists?(branch)
      System.result("git show-ref refs/heads/#{branch}") != ''
    end

    def development?
      name == DEVELOPMENT_BRANCH_NAME
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
      System.call "push origin #{name}"
    end

    def pull(branch)
      System.call "pull origin #{branch}"
    end

    def checkout
      System.call "checkout #{name}"
    end

    def authorize_delete!
      raise ProtectedBranchError, "The #{name} branch is protected" if protected?
    end

    attr_reader :name
    alias_method :to_s, :name

  end
end
