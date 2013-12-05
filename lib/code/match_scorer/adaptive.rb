require 'code/match_scorer/contains_patterns_in_order'
require 'code/match_scorer/contains_all_patterns'

module MatchScorer
  class Adaptive < Base

    SUBSCORER_CLASSES = [MatchScorer::ContainsAllPatterns, MatchScorer::ContainsPatternsInOrder]

    def score(string)
      subscorers.inject(0) { |total, scorer| total + scorer.score(string).to_i }
    end

    def subscorers
      @subscorers ||= SUBSCORER_CLASSES.map { |k| k.new(patterns) }
    end

  end
end