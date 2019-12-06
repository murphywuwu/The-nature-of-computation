require_relative './helpers.rb'

# 正整数
ZERO    = -> p { -> x {       x    } }
ONE     = -> p { -> x {     p[x]   } }
TWO     = -> p { -> x {   p[p[x]]  } }
THREE   = -> p { -> x { p[p[p[x]]] } }
FIVE    = -> p { -> x { p[p[p[p[p[x]]]]] } }
FIFTEEN = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]] } }
HUNDRED = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]] } }


to_inerger(ZERO) # 0
to_inerger(THREE) # 3
to_inerger(FIVE) # 5
to_inerger(FIFTEEN) # 15
to_inerger(HUNDRED) # 100

# 布尔值
TRUE  =  -> x { -> y { x } }
FALSE = -> x { -> y { y } }
IF    = -> b { b }

to_boolean(TRUE)
to_boolean(FALSE)