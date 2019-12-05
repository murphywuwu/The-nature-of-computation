class Tape < Struct.new(:left, :middle, :right, :blank)
  def inspect
    "#< Tape #{left.join}(#{middle})#{right.join}"
  end

  def write(character)
    Tape.new(left, character, right, blank)
  end
  
  def move_head_left
    Tape.new(left[0..-2], left.last || blank, [middle]+right, blank)
  end

  def move_head_right
    Tape.new(left + [middle], right.first || blank, right.drop(1), blank)
  end
end

tape = Tape.new(['1', '0', '1'], '1', [], '_')
tape.middle # 1


tape
#< Tape 101(1)
tape.move_head_left
#< Tape 10(1)1
tape.write('0')
#< Tape 101(0)
tape.move_head_right
#< Tape 1011(_)
tape.move_head_right.write('0')
#< Tape 1011(0)