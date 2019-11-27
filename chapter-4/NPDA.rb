require('set')

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

# 记录PDA此刻的 状态和栈
class PDAConfiguration < Struct.new(:state, :stack)
  STUCK_STATE = Object.new

  def stuck
    PDAConfiguration.new(STUCK_STATE, stack)
  end

  def stuck?
    state == STUCK_STATE
  end
end

# 规则设置
class PDARule < Struct.new(:state, :character, :next_state, :pop_character, :push_characters)

  # 规则匹配：判断PDA当前状态，栈的内容，输入字符和规则是否匹配
  def applies_to?(configuration, character)
    self.state == configuration.state &&
    self.pop_character == configuration.stack.top &&
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

# 存储规则
class NPDARulebook < Struct.new(:rules)
  def next_configurations(configurations, character)
    configurations.flat_map { |config| follow_rules_for(config, character) }.to_set
  end

  def follow_rules_for(configuration, character)
    rules_for(configuration, character).map { |rule| rule.follow(configuration) }
  end
  
  def rules_for(configuration, character)
    rules.select { |rule| rule.applies_to?(configuration, character) }
  end

  def follow_free_moves(configurations)
    more_configurations = next_configurations(configurations, nil)

    if more_configurations.subset?(configurations)
      configurations
    else
      follow_free_moves(configurations + more_configurations)
    end
  end
end


# 接受字符串时，使用初始化机器状态重新创建生成npda
class NPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def accepts?(string)
    to_npda.tap { |npda| npda.read_string(string) }.accepting?
  end

  def to_npda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    NPDA.new(Set[start_configuration], accept_states, rulebook)
  end
end

# 接受字符串并跟踪改变机器的状态
class NPDA < Struct.new(:current_configurations, :accept_states, :rulebook)
  def accepting?
    current_configurations.any? { |config| accept_states.include?(config.state) }
  end

  def read_character(character)
    self.current_configurations = rulebook.next_configurations(current_configurations, character) 
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end

  def current_configurations
    rulebook.follow_free_moves(super)
  end
end

rulebook = NPDARulebook.new([
  PDARule.new(1, 'a', 1, '$', ['a', '$']),
  PDARule.new(1, 'a', 1, 'a', ['a', 'a']),
  PDARule.new(1, 'a', 1, 'b', ['a', 'b']),
  PDARule.new(1, 'b', 1, '$', ['b', '$']),
  PDARule.new(1, 'b', 1, 'a', ['b', 'a']),
  PDARule.new(1, 'b', 1, 'b', ['b', 'b']),
  PDARule.new(1, nil, 2, '$', ['$']),
  PDARule.new(1, nil, 2, 'a', ['a']),
  PDARule.new(1, nil, 2, 'b', ['b']),
  PDARule.new(2, 'a', 2, 'a', []),
  PDARule.new(2, 'b', 2, 'b', []),
  PDARule.new(2, nil, 3, '$', ['$']),
])

configuration = PDAConfiguration.new(1, Stack.new(['$']))
npda = NPDA.new(Set[configuration], [3], rulebook)
npda.accepting?
npda.current_configurations

# #<Set: {
  #<struct PDAConfiguration state=1, stack=#<struct Stack contents=["$"]>>, 
  #<struct PDAConfiguration state=2, stack=#<struct Stack contents=["$"]>>, 
  #<struct PDAConfiguration state=3, stack=#<struct Stack contents=["$"]>>}>

npda.read_string('abb')
npda.accepting? # false
npda.current_configurations

 # #<Set: {
   #<struct PDAConfiguration state=1, stack=#<struct Stack contents=["b", "b", "a", "$"]>>, 
   #<struct PDAConfiguration state=2, stack=#<struct Stack contents=["a", "$"]>>, 
   #<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "b", "a", "$"]>>}>

npda_design = NPDADesign.new(1, '$', [3], rulebook)
npda_design.accepts?('abba') # true
npda_design.accepts?('babbaabbab') # true
npda_design.accepts?('abb') # false
npda_design.accepts?('baabaa') # false