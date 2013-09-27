module Code
  module System
    extend self

    COLORS = {black: 30, red: 31, green: 32, yellow: 33, blue: 34, magenta: 35, teal: 36}

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

  end
end
