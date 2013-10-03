class FileList
  include Enumerable

  def initialize(base_path = '.')
    @base_path = base_path
  end

  def each(&block)
    Dir['**/**'].each(&block)
  end

  def matching(*patterns)
    patterns = coerce_patterns(*patterns)
    select { |path|
      patterns.all? { |pattern| path.downcase.include? pattern.downcase }
    }
  end

  private

  attr_reader :base_path

  def coerce_patterns(*patterns)
    Array(patterns).join(' ').split(' ')
  end

end