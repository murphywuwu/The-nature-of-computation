def to_inerger(proc)
  proc[ -> n { n + 1 } ][0]
end

def to_boolean(proc)
  proc[true][false]
end