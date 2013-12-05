require 'code/match_scorer/base'

module MatchScorer
  class ContainsPatternsInOrder < Base
    def score(string)
      4 if matches?(string)
    end

    def matches?(string)
      regexp_string = patterns.map { |p| Regexp.escape(p) }.join('.*')
      Regexp.new(regexp_string) == string
    end
  end
end