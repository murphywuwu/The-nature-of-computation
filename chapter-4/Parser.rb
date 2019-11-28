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

# 词法分析
class LexicalAnalyzer < Struct.new(:string)
  GRAMMAR = [
    { token: 'i', pattern: /if/ }, # if 关键字
    { token: 'e', pattern: /else/ },  # else关键字
    { token: 'w', pattern: /while/ },  # while关键字
    { token: 'd', pattern: /do-nothing/ },  # do-nothing关键字
    { token: '(', pattern: /\(/ },  # 左小括号
    { token: ')', pattern: /\)/ },  # 右小括号
    { token: '{', pattern: /\{/ },  # 左大括号
    { token: '}', pattern: /\}/ },  # 右大括号
    { token: ';', pattern: /;/ },  # 分号
    { token: '=', pattern: /=/ },  # 等号
    { token: '+', pattern: /\+/ },  # 加号
    { token: '*', pattern: /\*/ },  # 乘号
    { token: '<', pattern: /</ },  # 小于号
    { token: 'n', pattern: /[0-9]+/ },  # 数字
    { token: 'b', pattern: /true|false/ },  # 布尔值
    { token: 'v', pattern: /[a-z]+/ },  # 变量名
  ]

  def analyze
    [].tap do |tokens|
      while more_tokens?
        tokens.push(next_token)
      end
    end
  end

  def more_tokens?
    !string.empty?
  end

  def next_token
    rule, match = rule_mathing(string)

    # puts "规则: #{rule}, 匹配项: #{match}"
    # 重置字符串
    self.string  = string_after(match)
    
    rule[:token]
  end

  def rule_mathing(string)
    matches = GRAMMAR.map { |rule| match_at_beginning(rule[:pattern], string) }
    # zip： 合并数组
    rule_with_matches = GRAMMAR.zip(matches).reject { |rule, match| match.nil? }
    # puts "匹配结果 #{rule_with_matches}"

    # 返回结果
    rule_with_longest_match(rule_with_matches)
  end

  def match_at_beginning(pattern, string) 
    # \A：匹配字符串的开头
    # 正则表达式：/A(?-mix:#{pattern})/
    /\A#{pattern}/.match(string)
  end

  def rule_with_longest_match(rule_with_matches)
    # 在所有匹配结果中，选择匹配项字符较长的结果
    rule_with_matches.max_by { |rule, match| match.to_s.length }
  end

  def string_after(match)
    match.post_match.lstrip
  end
end


LexicalAnalyzer.new('y = x * 7').analyze
# ["v", "=", "v", "*", "n"]

LexicalAnalyzer.new('while (x < 5) { x = x * 3 }').analyze
# ["w", "(", "v", "<", "n", ")", "{", "v", "=", "v", "*", "n", "}"]

LexicalAnalyzer.new('if (x < 10) { y = true; x = 0 } else { do-nothing }').analyze
# ["i", "(", "v", "<", "n", ")", "{", "v", "=", "b", ";", "v", "=", "n", "}", "e", "{", "d" ,"}"]


LexicalAnalyzer.new('x = false').analyze
# ["v", "=", "b"]
# 比如下例中的字符falsehood, 对于正则表达式/true|false/以及/[a-z]+/都能匹配上
# 而根据最长匹配规则进行选择，flasehood字符串的结果就匹配为v，以免造成变量名被错误的识别为关键字
# 解决这个问题还有其他方法。一种就是在规则中使用规则性更强的正则表达式：如果布尔值的规则使用模式/(true|false)?![a-z]/，那它就不会首先匹配字符串'falsehood'了
LexicalAnalyzer.new('x = falsehood').analyze
# ["v", "=", "v"]

# PDA启动的时候，立即把一个符号推入栈中，这个符号表示它正在试图识别的结构。我们想要识别Simple语句，所以PDA开始时要把S推入栈中
start_rule = PDARule.new(1, nil, 2, '$', ['S', '$'])

# 选取一个字符表示**文法**中的每个符号。在这种情况下，我们使用每个符号的大写首字母--S表示”<语句>“， W表示"While"，以此类推，这是为了与我们已经用来作为单词的小写字符区分开

# 把**文法规则**转换成无需任何输入就能扩展栈顶的PDA规则。每一个**文法规则**描述了如何把一个符号扩展成由其他符号和单词组成的序列。
# 我们把这个描述转成一个PDA规则，它把一个代表特定符号的字符弹出栈并把其他字符推入栈中
symbol_rules = [
  # <statement> :: = <while> | <assign>
  PDARule.new(2, nil, 2, 'S', ['W']),
  PDARule.new(2, nil, 2, 'S', ['A']),

  # while :: = 'w' '(' <expression> ')' '{' <statement> '}'
  PDARule.new(2, nil, 2, 'W', ['w', '(', 'E', ')', '{', 'S', '}']),
  
  # <assign> :: = 'v' '=' <expression>
  PDARule.new(2, nil, 2, 'A', ['v', '=', 'E']),

  # <expression> :: = <less-than>
  PDARule.new(2, nil, 2, 'E', ['L']),

  # <less-than> :: = <multipy> '<' <less-than> | <multiply>
  PDARule.new(2, nil, 2, 'L', ['M', '<', 'L']),
  PDARule.new(2, nil, 2, 'L', ['M']),

  # <multiply> :: = <term> '*' <multiply> | <term>
  PDARule.new(2, nil, 2, 'M', ['T', '*', 'M']),
  PDARule.new(2, nil, 2, 'M', ['T']),

  # <term> :: = 'n' | 'v'
  PDARule.new(2, nil, 2, 'T', ['n']),
  PDARule.new(2, nil, 2, 'T', ['v']),
]

# 为每一个单词字符赋予一个PDA规则，这个规则从输入读取字符然后把它从栈中弹出
token_rules = LexicalAnalyzer::GRAMMAR.map do |rule|
  PDARule.new(2, rule[:token], 2, rule[:token], [])
end

# 最好，生成一个PDA规则，当栈变空时它允许机器进入接收状态
stop_rule = PDARule.new(2, nil, 3, '$', ['$'])

# 单词规则与符号规则的工作方式相反。符号规则试图让栈变大，有时候会推入一些字符以替换已经弹出的；
# 单词规则总是让栈变小，随着栈的变小处理输入
rulebook = NPDARulebook.new([start_rule, stop_rule] + symbol_rules + token_rules)

npda_design = NPDADesign.new(1, '$', [3], rulebook)

token_string = LexicalAnalyzer.new('while (x < 5) { x = x * 3 }').analyze.join
# "w(v<n){v=v*n}"
npda_design.accepts?(token_string)
# true
npda_design.accepts?(LexicalAnalyzer.new('while ( x < 5 x = x * }').analyze.join)
# false