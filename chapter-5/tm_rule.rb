
require_relative './tm_configuration.rb'
require_relative './tape.rb'

class TMRule < Struct.new(:state, :character, :next_state, :write_character, :direction)
  def applies_to?(configuration)
    state == configuration.state && character == configuration.tape.middle
  end
end

rule = TMRule.new(1, '0', 2, '1', :right)
rule.applies_to?(TMConfiguration.new(1, Tape.new([], '0', [], '_'))) # true
rule.applies_to?(TMConfiguration.new(1, Tape.new([], '1', [], '_'))) # false
rule.applies_to?(TMConfiguration.new(2, Tape.new([], '0', [], '_'))) # false
