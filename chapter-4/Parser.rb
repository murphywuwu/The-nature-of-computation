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

