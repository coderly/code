require 'code/match_scorer/base'

module MatchScorer
  class ContainsAllPatterns < Base
    def score(string)
      2 if matches? string
    end

    def matches?(string)
      patterns.all? { |pattern| string.downcase.include? pattern.downcase }
    end
  end
end
