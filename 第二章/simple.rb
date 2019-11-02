class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
     " <<#{self}>> "
  end

  def reducible?
    false
  end
end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    " <<#{self}>>"
  end

  def reducible?
     true
  end

  def reduce(enviroment)
    if left.reducible?
      Add.new(left.reduce(enviroment), right)
    elsif right.reducible?
      Add.new(left, right.reduce(enviroment))
    else
      Number.new(left.value + right.value)
    end
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
     " <<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(enviroment)
    if left.reducible?
      Multiply.new(left.reduce(enviroment), right)      
    elsif right.reducible?
      Multiply.new(left, right.reduce(enviroment))
    else
      Number.new(left.value * right.value)
    end
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    " <<#{self}>>"
  end

  def reducible?
    false
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    " <<#{self}>>"
  end

  def reducible?
    true 
  end

  def reduce(enviroment)
    if left.reducible?
      LessThan.new(left.reduce(enviroment), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(enviroment))
    else
      Boolean.new(left.value < right.value)
    end
  end
end

class Variable < Struct.new(:name) 
  def to_s
    name.to_s
  end

  def inspect
    " <<#{self}>>"
  end

  def reducible?
    true
  end

  def reduce(enviroment)
    enviroment[name]
  end 
end

class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    " <<#{self}>> "
  end

  def ==(other_statement)
    other_statement.instance_of?(DoNothing)
  end

  def reducible?
    false
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    " <<#{self}>> "
  end

  def reducible?
    true
  end

  def reduce(enviroment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(enviroment)), enviroment]
    else
      [DoNothing.new, enviroment.merge({ name => expression })]
    end
  end
end


class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect
    " <<#{self}>> "
  end

  def reducible?
    true
  end

  def reduce(enviroment)
    if condition.reducible?
      [If.new(condition.reduce(enviroment), consequence, alternative), enviroment]
    else
      case condition
      when Boolean.new(true)
        [consequence, enviroment]
      when Boolean.new(false)
        [alternative, enviroment]
      end
    end
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    " <<#{self}>> "
  end

  def reducible?
    true
  end

  def reduce(enviroment)
    case first

    when DoNothing.new
      [second, enviroment]
    else
      reduce_first, reduced_enviroment = first.reduce(enviroment)
      [Sequence.new(reduce_first, second), reduced_enviroment]
    end
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
  end

  def inspect
    " <<#{self}>> "
  end 

  def reducible?
    true
  end

  def reduce(enviroment)
    [If.new(condition, Sequence.new(body, self), DoNothing.new), enviroment]
  end
end

class Machine < Struct.new(:statement, :enviroment)
  def step
    self.statement, self.enviroment = statement.reduce(enviroment)
  end

  def run
    while statement.reducible?
      puts "#{statement}, #{enviroment}"
      step
    end
    puts "#{statement}, #{enviroment}"
  end
end

Machine.new(
  While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
  ),
  { x: Number.new(1) }
).run