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

rule = PDARule.new(1, '(', 2, '$', ['b', '$'])

configuration = PDAConfiguration.new(1, Stack.new(['$']))
rule.applies_to?(configuration, '(') # true

rule.follow(configuration)
# <struct PDAConfiguration state = 2, stack=#<Stack (b)$>>

# 规则存储
class DPDARulebook < Struct.new(:rules)
  # 将和当前PDA匹配的规则，应用于当前PDA
  def next_configuration(configuration, character)
    rule_for(configuration, character).follow(configuration);
  end
  
  # 根据当前状态，栈以及输入，检测和当前PDA匹配的规则
  # 确定性：当前的状态和栈只能匹配上一个规则
  def rule_for(configuration, character)
    rules.detect { |rule|  rule.applies_to?(configuration, character) }
  end

  def applies_to?(configuration, character)
    !rule_for(configuration, character).nil?
  end
  
  # 自由移动: 不断地反复执行能应用到当前配置的任何自由移动，直到没有自由自动的时候才会停止
  def follow_free_moves(configuration)
    if applies_to?(configuration, nil)
      follow_free_moves(next_configuration(configuration, nil))
    else
      configuration
    end
  end
end

rulebook = DPDARulebook.new([
  PDARule.new(1, '(', 2, '$', ['b', '$']),
  PDARule.new(2, '(', 2, 'b', ['b', 'b']),
  PDARule.new(2, ')', 2, 'b', []),
  PDARule.new(2, nil, 1, '$', ['$'])
]);

configuration = rulebook.next_configuration(configuration, '(')
#<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "$"]>>
configuration = rulebook.next_configuration(configuration, '(')
#<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "b", "$"]>>
configuration = rulebook.next_configuration(configuration, ')')
#<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "$"]>>

# 能够读取字符串，并存储跟踪PDA的当前状态
class DPDA < Struct.new(:current_configuration, :accept_states, :rulebook)
  def current_configuration
    rulebook.follow_free_moves(super)
  end

  def accepting?
    accept_states.include?(current_configuration.state)
  end

  def next_configuration(character)
    if rulebook.applies_to?(current_configuration, character)
      rulebook.next_configuration(current_configuration, character)
    else
      current_configuration.stuck
    end
  end

  def stuck?
    current_configuration.stuck?
  end

  def read_character(character)
    self.current_configuration = (next_configuration(character))
    puts "#{(next_configuration(character))}"
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character) unless stuck?
    end
  end
end

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)

dpda.accepting? # true
dpda.read_string('(()')
dpda.accepting? # false
dpda.current_configuration
#<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "$"]>>


configuration = PDAConfiguration.new(2, Stack.new(['$']))
rulebook.follow_free_moves(configuration)
 #<struct PDAConfiguration state=1, stack=#<struct Stack contents=["$"]>>

 dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
 dpda.read_string('(()(')
 dpda.accepting?# false
 dpda.current_configuration
 #<struct PDAConfiguration state=2, stack=#<struct Stack contents=["b", "b", "$"]>>

 dpda.read_string('))()')
 dpda.accepting? # true

 dpda.current_configuration
 #<struct PDAConfiguration state=1, stack=#<struct Stack contents=["$"]>>

# 创建pda
class DPDADesign < Struct.new(:start_state, :bottom_character, :accept_states, :rulebook)
  def accepts?(string)
    to_dpda.tap { |dpda| dpda.read_string(string) }.accepting?
  end

  def to_dpda
    start_stack = Stack.new([bottom_character])
    start_configuration = PDAConfiguration.new(start_state, start_stack)
    DPDA.new(start_configuration, accept_states, rulebook)
  end
end

dpda_design = DPDADesign.new(1, '$', [1], rulebook)

dpda_design.accepts?('(((((((((())))))))))')

dpda_design.accepts?('()(())((()))(()(()))')

dpda_design.accepts?('(()(()(()()(()()))()')

# 之所以发生这种情况，是因为DPDARulebook#next_configuration假设它总能找到可用的规则，因此在没有规则可用的时我们不应该调用它、
dpda_design.accepts?('())') # false
# NoMethodError: undefined method `follow' for nil:NilClass

dpda = DPDA.new(PDAConfiguration.new(1, Stack.new(['$'])), [1], rulebook)
dpda.read_string('())');
dpda.accepting? # false
dpda.current_configuration
dpda.stuck? # true

dpda_design.accepts?('(()') # false

rulebook = DPDARulebook.new([
  PDARule.new(1, 'a', 2, '$', ['a', '$']),
  PDARule.new(1, 'b', 2, '$', ['b', '$']),
  
  # b在栈顶
  # 读到b，就积累b
  PDARule.new(2, 'b', 2, 'b', ['b', 'b']),
  # 读到a，就弹出b
  PDARule.new(2, 'a', 2, 'b', []),

  # a在栈顶
  # 意味着机器已经看到a过剩了，因此任何额外从输入读取的a将会在栈中积累
  PDARule.new(2, 'a', 2, 'a', ['a', 'a']),
  # 而每读到一个b就会从栈中弹出一个a作为抵消
  PDARule.new(2, 'b', 2, 'a', []),

  PDARule.new(2, nil, 1, '$', ['$']),
])

dpda_design = DPDADesign.new(1, '$', [1], rulebook)

dpda_design.accepts?('ababab')
dpda_design.accepts?('bbbaaaab')
dpda_design.accepts?('baa')