class String
  alias has? include?

  def rm_chr(*chrs)
    self_obj = self
    chrs.each do |chr|
      self_obj = self_obj.gsub(chr, ' ')
    end
    self_obj
  end

  def or_eql?(*others)
    result = []
    others.each do |other|
      result << self == other
    end
    result.any?
  end

  def starting_space_count
    count = 0
    each_char do |c|
      break unless c == ' '
      count += 1
    end
    count
  end
end