require "parseconfig"

module Code

  PROMPT_TEXTS = {

  }

  module Config
    extend self

    def self.get(property)
      ensure_file_exists

      config = ParseConfig.new ".codeconfig"

      if config[property]
        property_value = config[property] if config[property]
      else
        property_value = System.prompt(PROMPT_TEXTS[property] || "Unknown") unless config[property]
        config.add(property, property_value)
        file = File.open ".codeconfig", "w"
        config.write file
        file.close
      end
      property_value
    end

    def self.ensure_file_exists
      FileUtils.touch ".codeconfig" unless File.exists? ".codeconfig"
    end
  end
end