# 栈
class Stack < Struct.new(:contents)
  def push(character)
    Stack.new([character] + contents)
  end

  def pop()
    Stack.new(contents.drop(1))
  end

  def top()
    contents.first
  end

  def insepct
    "#<Stack (#{top}#{contents.drop(1).join()})>"
  end
end

stack = Stack.new(['a', 'b', 'c', 'd', 'e'])
stack.pop() # a
stack.pop.pop.top # c
stack.push('x').push('y').top # y
stack.push('x').push('y').pop.pop # x

# 记录PDA此刻的 状态和栈
class PDAConfiguration < Struct.new(:state, :stack)

end

# 规则设置
class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_characters)

  # 规则匹配：判断PDA当前状态，栈的内容，输入字符和规则是否匹配
  def applies_to?(configuration, character)
    self.state == configuration.state &&
    self.pop_character = configuration.stack.pop &&
    self.character == character
  end

  # 规则使用：根据规则更新PAD的状态，栈
  def follow(configuration)
    PDAConfiguration.new(next_state, next_stack(configuration))
  end
  
  def next_stack(configuration)
    popped_statck = configuration.stack.pop

    push_characters.reverse.
      inject(popped_statck) { |stack, character| stack.push(character) }
  end
end

rule = PDARule.new(1, '(', 2, '$', ['b', '$'])

configuration = PDAConfiguration.new(1, Stack.new(['$']))
rule.applies_to?(configuration, '(') # true

rule.follow(configuration)
# <struct PDAConfiguration state = 2, stack=#<Stack (b)$>>