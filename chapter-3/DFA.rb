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
