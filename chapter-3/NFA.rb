require('set');

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow()
    next_state
  end

  def inspect
    "#<FARule #{state.inspect} -- #{character} --> #{next_state.inspect}"
  end
end

class NFARuleBook < Struct.new(:rules)
  def next_states(states,character)
    # 遍历当前可能的状态，根据输入character获的对应的规则，并返回next_state
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  # 找到所有在没有任何输入时的起始状态
  def follow_free_moves(states) 
    more_states = next_states(states, nil);

    # 由next_states(states, nil)找到的每一个状态都已经包含在states里时，它就返回找到的所有状态
    if more_states.subset?(states)
      states
    else
      follow_free_moves(states + more_states);
    end
  end
  
  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) } 
  end
end

rulebook = NFARuleBook.new([
  FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
  FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 4), FARule.new(3, 'b', 4),
])

rulebook.next_states(Set[1], 'b')
# <Set: {1, 2}>
rulebook.next_states(Set[1, 2], 'a')
# <Set: {1, 3}>
rulebook.next_states(Set[1,3], 'b')
# <Set: {1, 2, 4}>

# NFA: 
# 可读取字符串，并根据事先预置好的rulebook，转换其状态
# 同时也可判断转换后的状态是否是处于可接受状态
class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def read_character(character)
    self.current_states = rulebook.next_states(current_states(),character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end

  def current_states
    rulebook.follow_free_moves(super)
  end

  # 这个NFA类与我们之前的DFA非常相似。不同的是，它有一个当前可能的状态集合current_states，
  # 而不是只e有一个当前的确定状态current_state，因此如果currnt_state例有一个是接受状态，就说它处于接受状态
  def accepting?
    (current_states & accept_states).any?
  end
end

NFA.new(Set[1], [4], rulebook).accepting? # false
NFA.new(Set[1, 2, 4], [4], rulebook).accepting? # true

nfa = NFA.new(Set[1], [4], rulebook);
nfa.accepting? # false
nfa.read_character('b')
nfa.accepting? # false
nfa.read_character('a')
nfa.accepting? # false
nfa.read_character('b')
nfa.accepting? # true

nfa = NFA.new(Set[1], [4], rulebook);
nfa.accepting? # false
nfa.read_string('bbbbb');
nfa.accepting? # true

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook )
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

nfa_design = NFADesign.new(1, [4], rulebook);

nfa_design.accepts?('bab') # true
nfa_design.accepts?('bbbbb') # true
nfa_design.accepts?('bbabb') # false

rulebook = NFARuleBook.new([
  FARule.new(1, nil, 2), FARule.new(1, nil, 4),
  FARule.new(2, 'a', 3),
  FARule.new(3, 'a', 2),
  FARule.new(4, 'a', 5),
  FARule.new(5, 'a', 6),
  FARule.new(6, 'a', 4),
]);

rulebook.next_states(Set[1], nil)
# <Set: {2, 4}>

rulebook.follow_free_moves(Set[1])
# <Set: {1, 2, 4}>

nfa_design = NFADesign.new(1, [2, 4], rulebook);
nfa_design.accepts?('aa') # true
nfa_design.accepts?('aaa') # true
nfa_design.accepts?('aaaaa') # false
nfa_design.accepts?('aaaaaa') # true
