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

# 规则
class PDAConfiguration < Struct.new(:state, :stack)

end

class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_character)
  def applies_to?(configuration, character)
    self.state == configuration.state &&
    self.pop_character = configuration.stack.pop &&
    self.character == character
  end
end

rule = PDARule.new(1, '(', 2, '$', ['b', '$'])

configuration = PDAConfiguration.new(1, Stack.new(['$']))
rule.applies_to?(configuration, '(') # true

