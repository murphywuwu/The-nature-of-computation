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
LEFT = -> p { p[ -> x { -> y { x } }]  }
RIGHT = -> p { p[ -> x { -> y { y } }] }

my_pair = PAIR[THREE][FIVE]
to_interger(LEFT[my_pair]) # 3
to_interger(RIGHT[my_pair]) # 5

INCREMENT = -> n { -> p { -> x { p[n[p][x]] } } }
SLIDE     = -> p { PAIR[RIGHT[p]][INCREMENT[RIGHT[p]]] }
DECREMENT = -> n { LEFT[n[SLIDE][PAIR[ZERO][ZERO]]] }

to_interger(DECREMENT[FIVE]) # 4
to_interger(DECREMENT[FIFTEEN]) # 14
to_interger(DECREMENT[HUNDRED]) # 99
to_interger(DECREMENT[ZERO])# 0

ADD = -> m { -> n { n[INCREMENT][m] } }
SUBTRACT = -> m { -> n { n[DECREMENT][m] } }
MULTIPLY = -> m { -> n { n[ADD[m]][ZERO] } } 
POWER = -> m { -> n { n[MULTIPLY[m]][ONE] } }

# m <= n的话，SUBTRACT[m][n]会返回zero
IS_LESS_OR_EQUAL = -> m {
  -> n {
    IS_ZERO[SUBTRACT[m][n]]
  }
}

to_boolean(IS_LESS_OR_EQUAL[ONE][TWO]) # true
to_boolean(IS_LESS_OR_EQUAL[TWO][TWO]) # true
to_boolean(IS_LESS_OR_EQUAL[THREE][TWO]) # false