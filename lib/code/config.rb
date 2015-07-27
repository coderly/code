require "parseconfig"

module Code

  PROMPT_TEXTS = {
    master_branch: "You didn't set the name of the master branch. What is it ('master')?",
    development_branch: "You didn't set the name of the development branch. What is it ('development')?"
  }

  DEFAULTS = {
    master_branch: "master",
    development_branch: "development"
  }

  module Config
    extend self

    def self.get(property)
      ensure_file_exists
      get_property_value(property)
    end

    def self.get_master_branch_name
      self.get(:master_branch)
    end

    def self.get_development_branch_name
      self.get(:development_branch)
    end

    private

    def ensure_file_exists
      FileUtils.touch ".codeconfig" unless File.exists? ".codeconfig"
    end

    def get_property_value(property)
      config = ParseConfig.new ".codeconfig"

      if config[property.to_s]
        property_value = config[property.to_s]
      else
        property_value = System.prompt(PROMPT_TEXTS[property] || "Unknown") unless config[property]

        store_property_to_config(property, property_value, config)
      end

      property_value
    end

    def store_property_to_config(property, property_value, config)
      config.add(property, property_value) if property_value
      config.add(property, DEFAULTS[property]) unless property_value

      file = File.open ".codeconfig", "w"
      config.write file
      file.close
    end
  end
end
