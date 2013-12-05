module MatchScorer
  class Base
    def initialize(*patterns)
      @patterns = coerce_patterns(*patterns)
    end

    def score(string)
      raise NotImplementedError, "Must implement #{__method__} for #{self.class}"
    end

    protected

    attr_reader :patterns

    private

    def coerce_patterns(*patterns)
      Array(patterns).join(' ').split(' ')
    end

  end
end
