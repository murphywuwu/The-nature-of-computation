require_relative './tm_rule.rb'
require_relative './tm_configuration.rb'
require_relative './tape.rb'

class DTMRulebook < Struct.new(:rules)
  # 根据规则和当前配置，判断图灵机是否处于卡死状态
  def applies_to?(configuration)
    !rule_for(configuration).nil?
  end

  def next_configuration(configuration)
    rule_for(configuration).follow(configuration)
  end
  
  def rule_for(configuration)
    rules.detect { |rule| rule.applies_to?(configuration) }
  end
end

tape = Tape.new(['1', '0', '1'], '1', [], '_')


rulebook = DTMRulebook.new([
  TMRule.new(1, '1', 1, '0', :left),
  TMRule.new(1, '0', 2, '1', :right),
  TMRule.new(1, '_', 2, '1', :right),
  TMRule.new(2, '0', 2, '0', :right),
  TMRule.new(2, '1', 2, '1', :right),
  TMRule.new(2, '_', 3, '_', :left)
])

configuration = TMConfiguration.new(1, tape)
#<struct TMConfiguration state=1, tape=#< Tape 101(1)>
configuration = rulebook.next_configuration(configuration)
#<struct TMConfiguration state=1, tape=#< Tape 10(1)0>
configuration = rulebook.next_configuration(configuration)
#<struct TMConfiguration state=1, tape=#< Tape 1(0)00>
configuration = rulebook.next_configuration(configuration)
#<struct TMConfiguration state=2, tape=#< Tape 11(0)0>