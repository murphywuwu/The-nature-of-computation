def to_inerger(proc)
  proc[ -> n { n + 1 } ][0]
end

def to_boolean(proc)
  IF[proc][true][false]
end