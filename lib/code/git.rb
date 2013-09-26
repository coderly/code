require 'uri'

module Code

  class Git

    COLORS = {black: 30, red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, teal: 36}

    def start(feature)
      ensure_feature_missing! feature

      pull main_branch
      checkout main_branch unless on_main_branch?

      create_branch feature
      checkout feature
    end

    def switch(*patterns)
      branch = branch_matching *patterns
      checkout branch
    end

    def branch_matching(*patterns)
      branches.find { |b| branch_matches? b, *patterns } or abort "No branch matching #{patterns.join ' '} exists"
    end

    def branch_matches?(branch, *patterns)
      patterns.all? { |p| branch.include? p }
    end

    def branches
      `git branch`.strip.lines.map { |line| line.gsub(/\s|\*/, '') }
    end

    def cancel
      if on_main_branch?
        puts "Nothing to cancel (already on #{main_branch})"
      else
        branch = current_branch
        checkout main_branch
        delete_branch branch, force: true
      end
    end

    def publish(message = '')
      ensure_clean_slate!
      push current_branch
      open_in_browser pull_request(message)
    end

    def pull_request(message = '')
      message = current_branch isdf message.empty?
      command = "hub pull-request -f \"#{message}\" -b #{main_repo}:development -h #{main_repo}:#{current_branch}"
      exec(command).strip
    end

    def compare_in_browser(branch)
      exec "hub compare #{branch}"
    end

    def finish
      branch = current_branch

      checkout main_branch
      fetch
      pull main_branch

      delete_branch branch
    end

    def files_changed?
      diff = `git diff --name-status`.strip
      diff != ''
    end

    def push(branch)
      call "push origin #{branch}"
    end

    def checkout(branch)
      call "checkout #{branch}"
    end

    def fetch
      call 'fetch'
    end

    def create_branch(branch)
      call "branch #{branch}"
    end

    def delete_branch(branch, force: false)
      ensure_safe_branch! branch

      flag = force ? '-D' : '-d'
      call "branch #{flag} #{branch}"
    end

    def delete_remote_branch(branch)
      call "push origin :#{branch}"
    end

    def current_branch
      `git symbolic-ref HEAD`.strip.split('/')[-1]
    end

    def main_branch
      'development'
    end

    def main_repo
      main_repo_url[/:(\w+)\//,1]
    end

    def main_repo_url
      repo_url 'origin'
    end

    def repo_url(name)
      `git ls-remote --get-url #{name}`.strip
    end

    def on_main_branch?
      on_branch? main_branch
    end

    def on_branch? branch
      current_branch == branch
    end

    def branch_exists?(branch)
      ref = `git show-ref refs/heads/#{branch}`.strip
      ref != ''
    end
    alias_method :feature_exists?, :branch_exists?

    def pull(branch)
      call "pull origin #{branch}"
    end

    def call(params)
      exec "git #{params}"
    end

    def color(script, color)
      value = COLORS[color]
      "\033[0;#{value}m" + script + "\033[m"
    end

    def green(script)
      color script, :green
    end

    def red(script)
      color script, :magenta
    end

    def ensure_safe_branch!(branch)
      error "branch #{branch} is protected" if protected_branch? branch
    end

    def protected_branch? branch
      %w{master development}.include? branch
    end

    def ensure_feature_missing!(feature)
      error "The #{feature} feature already exists" if feature_exists?(feature)
    end

    def ensure_clean_slate!
      if files_changed?
        error "Please stash or commit your code"
      end
    end

    def error(message)
      abort red(message)
    end

    def open_in_browser(url)
      open url if url =~ URI::regexp
    end

    def open(item)
      `open #{item}`
    end

    def exec(script)
      puts green(script)
      %x[#{script}]
    end

  end

end
