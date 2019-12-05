
require_relative './tm_configuration.rb'
require_relative './tape.rb'

class TMRule < Struct.new(:state, :character, :next_state, :write_character, :direction)
  def applies_to?(configuration)
    state == configuration.state && character == configuration.tape.middle
  end

  # 图灵机配置：根据规则，更新配置
  def follow(configuration)
    TMConfiguration.new(next_state, next_tape(configuration))
  end

  def next_tape(configuration)
    written_tape = configuration.tape.write(write_character)
    
    case direction
    when :left
      written_tape.move_head_left

    when :right
      written_tape.move_head_right
    end
  end
end

rule = TMRule.new(1, '0', 2, '1', :right)
rule.applies_to?(TMConfiguration.new(1, Tape.new([], '0', [], '_'))) # true
rule.applies_to?(TMConfiguration.new(1, Tape.new([], '1', [], '_'))) # false
rule.applies_to?(TMConfiguration.new(2, Tape.new([], '0', [], '_'))) # false

rule.follow(TMConfiguration.new(1, Tape.new([], '0', [], '_')))
#<struct TMConfiguration state=2, tape=#< Tape 1(_)>