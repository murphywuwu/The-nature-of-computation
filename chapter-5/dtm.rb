
require_relative './tm_configuration.rb'
require_relative './tape.rb'
require_relative './tm_rule.rb'
require_relative './dtm_rulebook.rb'

class DTM < Struct.new(:current_configuration, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_configuration.state)
  end

  def step
    self.current_configuration = rulebook.next_configuration(current_configuration)
  end

  def run
    step until accepting?
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


dtm = DTM.new(TMConfiguration.new(1, tape), [3], rulebook)
dtm.current_configuration
#<struct TMConfiguration state=1, tape=#< Tape 101(1)>
dtm.accepting? # false
dtm.step
dtm.current_configuration
#<struct TMConfiguration state=1, tape=#< Tape 10(1)0>
dtm.accepting? # false
dtm.run
dtm.current_configuration
#<struct TMConfiguration state=3, tape=#< Tape 110(0)_>
dtm.accepting? # true


