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
  # 假定总是恰好有一个规则应用到对应的状态和字符上。如果可用的规则超过一个，那么只有一个起作用，其他规则都忽略；
  # 如果没有可以应用的规则，#detect调用则返回nil，并且在视图调用nil.follow的时候模拟进程会崩溃。
  # 这就是为什么这个类叫DFARulebook而不是FARulebook了；它只在确定性约束满足的情况下才正确工作。
  def next_state(state, character)
    rule_for(state, character).follow
  end

  # 根据当前状态和输入获取对应到相应的规则
  def rule_for(state, character)
    rules.detect { | rule | rule.applies_to?(state, character) }
  end
end 

rulebook = DFARulebook.new([
  FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
  FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
  FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)
])

rulebook.next_state(1, 'a') # 2
rulebook.next_state(1, 'b') # 1
rulebook.next_state(2, 'b') # 3

# 跟踪当前状态，并报告它当前是否处于接受状态
class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end
  # 从输入中读取一个字符，然后查阅规则手册，再相应地改变状态
  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end
  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

DFA.new(1, [1,3], rulebook).accepting? # true
DFA.new(1, [3], rulebook).accepting? # false

dfa = DFA.new(1, [3], rulebook)
dfa.accepting? # false
dfa.read_character('b')
# current_state: 1 - [1, 'b', 1]
dfa.accepting? # false
# current_state: 2 - [1, 'a', 2]
# current_state: 2 - [2, 'a', 2]
# current_state: 2 - [2, 'a', 2]
3.times do dfa.read_character('a') end;
dfa.accepting? # false

# current_state: 3 - [2, 'b', '3']
dfa.read_character('b')
dfa.accepting? # true


dfa = DFA.new(1, [3], rulebook)
dfa.accepting? # false

# current_state: 1 - [1, 'b', 1]
# current_state  2 - [1, 'a', 2]
# current_state  2 - [2, 'a', 2]
# current_state  2 - [2, 'a', 2]
# current_state  3 - [2, 'b', 3]
dfa.read_string('baaab')
dfa.accepting? # true