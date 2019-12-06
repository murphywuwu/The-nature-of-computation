require_relative './helpers.rb'

# 正整数
ZERO    = -> p { -> x {       x    } }
ONE     = -> p { -> x {     p[x]   } }
TWO     = -> p { -> x {   p[p[x]]  } }
THREE   = -> p { -> x { p[p[p[x]]] } }
FIVE    = -> p { -> x { p[p[p[p[p[x]]]]] } }
FIFTEEN = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]] } }
HUNDRED = -> p { -> x { p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[p[x]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]] } }


to_interger(ZERO) # 0
to_interger(THREE) # 3
to_interger(FIVE) # 5
to_interger(FIFTEEN) # 15
to_interger(HUNDRED) # 100

# 布尔值
TRUE  =  -> x { -> y { x } }
FALSE = -> x { -> y { y } }
IF    = -> b { b }

to_boolean(TRUE)
to_boolean(FALSE)

# 谓词
IS_ZERO = -> n { n[-> x { FALSE }][TRUE] }

to_boolean(IS_ZERO[ZERO]) # true
to_boolean(IS_ZERO[THREE]) # false

# 有序对
PAIR = -> x { -> y { -> f { f[x][y] } } }
LFET = -> p { p[ -> x { -> y { x } }]  }
RIGHT = -> p { p[ -> x { -> y { y } }] }

my_pair = PAIR[THREE][FIVE]
to_interger(LFET[my_pair]) # 3
to_interger(RIGHT[my_pair]) # 5