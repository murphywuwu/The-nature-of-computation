require('set')

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow
    next_state
  end
  
  def inspect
    "#<FARule #{state.inspect} -- #{character} --> #{next_state.inspect}"
  end
end

class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_free_moves(states)
    more_states = next_states(states, nil);
    # 递归寻找到所有自由状态的自由状态
    if more_states.subset?(states)
      states
    else
      follow_free_moves(states+more_states) 
    end
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    # 根据现有状态和接收到的字符串，找到可以转换该状态的所有路线
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def read_character(character)
    self.current_states = rulebook.next_states(current_states(), character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end

  def current_states
    rulebook.follow_free_moves(super)
  end

  def accepting?
    (current_states & accept_states).any?
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    # 每调用一次都返回一个新的NFA，并重新设置起始状态
    # start_state: 起始状态
    # rulebook: 路线图，每一条规则都是一条路线(某个状态读取某个值变换到另一个状态的路线)
    # accept_states: 可接受状态
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

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
  
  def matches?(string)
    to_nfa_design.accepts?(string)
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

  def to_nfa_design
    start_state = Object.new
    accept_states = [start_state]
    rulebook = NFARulebook.new([])

    NFADesign.new(start_state, accept_states, rulebook)
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

  def to_nfa_design
    start_state = Object.new
    accept_state = Object.new
    rule = FARule.new(start_state, character, accept_state)
    rulebook = NFARulebook.new([rule])
    NFADesign.new(start_state, [accept_state], rulebook)
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

nfa_design = Empty.new.to_nfa_design
nfa_design.accepts?('') # true
nfa_design.accepts?('a') # false

nfa_design = Literal.new('a').to_nfa_design
nfa_design.accepts?('') # false
nfa_design.accepts?('a') # true

Empty.new().matches?('a') # false
Literal.new('a').matches?('a') # true