require('set');


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

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end

  def follow_free_moves(states)
    more_states = next_states(states, nil)

    if more_states.subset?(states)
      states
    else
      follow_free_moves(states+more_states)
    end
  end

  def alphabet
    rules.map(&:character).compact.uniq
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

  # 增加一个可选的参数“当前状态”，这样就可以使用任意集合的当前状态构建一台NFA，而不是只使用NFADesign的起始状态
  def to_nfa(current_states = Set[start_state])
    NFA.new(current_states, accept_states, rulebook)
  end
end

class NFASimulation < Struct.new(:nfa_design)
  def next_state(state, character)
    nfa_design.to_nfa(state).tap { |nfa| nfa.read_character(character)  }.current_states
  end

  def rules_for(state)
    nfa_design.rulebook.alphabet.map [
      |character|
       FARule.new(state, character, next_state(state, character))
    ]
  end
end

rulebook = NFARulebook.new([
  FARule.new(1, 'a', 1), FARule.new(1, 'a', 2), FARule.new(1, nil, 2),
  FARule.new(2, 'b', 3),
  FARule.new(3, 'b', 1), FARule.new(3, nil, 2)
])

nfa_design = NFADesign.new(1, [3], rulebook)
nfa_design.to_nfa.current_states; #<Set: {1, 2}>
nfa_design.to_nfa(Set[2]).current_states #<Set: {2}>
nfa_design.to_nfa(Set[3]).current_states #<Set: {3, 2}> 

# 现在我们可以用任何可能状态的集合创建一台NFA，向其输入一个字符，然后看它最终处于什么状态。
# 这是把一台NFA转换为DFA重要的一步。

nfa = nfa_design.to_nfa(Set[2, 3])
nfa.read_character('b');
nfa.current_states; #<Set: {3, 1, 2}>

simulation = NFASimulation.new(nfa_design)
simulation.next_state(Set[1, 2], 'a') #<Set: {1, 2}>
simulation.next_state(Set[1, 2], 'b') #<Set: {3, 2}>
simulation.next_state(Set[3, 2], 'b') #<Set: {1, 3, 2}>
simulation.next_state(Set[1, 3, 2], 'b') #<Set: {1, 3, 2}>
simulation.next_state(Set[1, 3, 2], 'a') #<Set: {1, 2}>

rulebook.alphabet # ["a", "b"]