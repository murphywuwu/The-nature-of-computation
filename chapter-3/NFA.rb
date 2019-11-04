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

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def read_character(character)
    self.current_states = rulebook.next_states(current_states,character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
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