require 'code/match_scorer/adaptive'

class FileList
  include Enumerable

  MATCHING = lambda { |o| o > 0 }

  def initialize(base_path = '.')
    @base_path = base_path
  end

  def each(&block)
    Dir['**/**'].each(&block)
  end

  def matching(*patterns)
    scorer = MatchScorer::Adaptive.new(*patterns)
    select { |p| scorer.score(p) > 0 }.sort { |a, b| scorer.score(a) <=> scorer.score(b) }
  end

  private

  attr_reader :base_path

end