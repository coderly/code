require "io/console"

require 'code/system/os'

module Code
  module System
    extend self

    CommandFailedError = ::Class.new(StandardError)

    COLORS = {black: 30, red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, teal: 36}

    def prompt(prompt_text)
      print prompt_text + ': '
      input = gets
      input.strip
    end

    def prompt_hidden(prompt_text)
      print prompt_text + ': '
      input = STDIN.noecho(&:gets)
      puts ''
      input.strip
    end

    def error(message)
      abort red(message)
    end

    def open_in_browser(url)
      open url if url =~ URI::regexp
    end

    def open(item)
      command = OS.current.open_command

      `#{command} #{item}`
    end

    def exec(script)
      puts green(script)
      result = %x[#{script}]
      raise CommandFailedError, red("command failed: #{script}") if command_failed?
      result
    end

    def command_failed?
      not $?.success?
    end

    def puts(text)
      Kernel.puts text
    end

    def call(params)
      exec "git #{params}"
    end

    def result(script)
      `#{script}`.strip
    end

    def color(script, color)
      value = COLORS[color]
      "\033[0;#{value}m" + script + "\033[m"
    end

    def green(script)
      color script, :green
    end

    def red(script)
      color script, :red
    end

  end
end
