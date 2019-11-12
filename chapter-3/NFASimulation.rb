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

class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    rule_for(state, character).follow
  end

  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end

  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end
  
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap { |dfa|  dfa.read_string(string) }.accepting?
  end
end

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
  # 取出规则中所有可能的输入字符串
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

  # 通过已知的模拟状态发现新的状态
  def rules_for(state)
    nfa_design.rulebook.alphabet.map {
      |character|
       FARule.new(state, character, next_state(state, character))
    }
  end

  def discover_states_rules(states)
    rules = states.flat_map { |state| rules_for(state) }
    more_states = rules.map(&:follow).to_set

    if more_states.subset?(states)
      [states, rules]
    else
      discover_states_rules(states + more_states)
    end
  end

  def to_dfa_design
    start_state = nfa_design.to_nfa.current_states
    states, rules = discover_states_rules(Set[start_state])

    accept_states = states.select { |state|  nfa_design.to_nfa(state).accepting? } 
    
    DFADesign.new(start_state, accept_states, DFARulebook.new(rules))
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
simulation.rules_for(Set[1, 2])
# [
   #<FARule #<Set: {1, 2}> -- a --> #<Set: {1, 2}>, 
   #<FARule #<Set: {1, 2}> -- b --> #<Set: {3, 2}>
# ]
simulation.rules_for(Set[3, 2])
# [
    #<FARule #<Set: {3, 2}> -- a --> #<Set: {}>, 
    #<FARule #<Set: {3, 2}> -- b --> #<Set: {1, 3, 2}>
# ]

start_state = nfa_design.to_nfa.current_states
simulation.discover_states_rules(Set[start_state])
#[
  #<Set: {#<Set: {1, 2}>, 
  #<Set: {3, 2}>, 
  #<Set: {}>, 
  #<Set: {1, 3, 2}>}>, 
  #[
    #<FARule #<Set: {1, 2}> -- a --> #<Set: {1, 2}>, 
    #<FARule #<Set: {1, 2}> -- b --> #<Set: {3, 2}>, 
    #<FARule #<Set: {3, 2}> -- a --> #<Set: {}>, 
    #<FARule #<Set: {3, 2}> -- b --> #<Set: {1, 3, 2}>, 
    #<FARule #<Set: {}> -- a --> #<Set: {}>, 
    #<FARule #<Set: {}> -- b --> #<Set: {}>, 
    #<FARule #<Set: {1, 3, 2}> -- a --> #<Set: {1, 2}>, 
    #<FARule #<Set: {1, 3, 2}> -- b --> #<Set: {1, 3, 2}>
  #]
#]

nfa_design.to_nfa(Set[1, 2]).accepting? # false
nfa_design.to_nfa(Set[2]).accepting? # false
nfa_design.to_nfa(Set[3]).accepting? # true
nfa_design.to_nfa(Set[2, 3]).accepting? # true


dfa_design = simulation.to_dfa_design
dfa_design.accepts?('aaa') # false
dfa_design.accepts?('aab') # true 
dfa_design.accepts?('bbbabb') # true