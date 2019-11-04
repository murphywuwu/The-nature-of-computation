module  Pattern
  # 如果该模式的优先级，比包裹该模式的外部模式的优先级低，则为该模式加括号
  def bracket(outer_precedence)
    puts "#{precedence}，#{outer_precedence}"
    if precedence < outer_precedence
      '(' + to_s + ')'
    else
     to_s
    end
  end 

  def inspect
    "/#{self}/"
  end
end

# ''
class Empty
  include Pattern
  
  def to_s
    ''
  end

  def precedence
    3
  end
end

# [a-z|A-Z]
class Literal < Struct.new(:character)
  include Pattern

  def to_s
    character
  end

  def precedence
    3
  end
end

class Concatenate < Struct.new(:first, :second)
  include Pattern

  def to_s
    [first, second].map { |pattern| pattern.bracket(precedence) }.join
  end

  def precedence
    1
  end
end

# |, 0
class Choose < Struct.new(:first, :second)
  include Pattern

  def to_s
    # 在
    [first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
  end

  # outer
  def precedence
    0
  end
end

# *, 2
class Repeat < Struct.new(:pattern)
  include Pattern

  def to_s
    pattern.bracket(precedence) + '*'
  end
  
  # outer
  def  precedence
    2
  end
end

pattern = Repeat.new(Literal.new('a'));
# /(a)*/
pattern = Repeat.new(
  Choose.new(
    Concatenate.new(Literal.new('a'), Literal.new('b')),
    Literal.new('a'),
  ),
)

# /(ab|a)*/