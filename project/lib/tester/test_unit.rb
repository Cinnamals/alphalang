require "test/unit"
require_relative "../locale_lister"

locale_used = File.read("#{LOCALES_PATH}/#{"default"}")
words_array = clean_locale_file_to_array(locale_used)
word_pair_hash = {}
words_array.each_with_index do |word, index|
  if index.even?
    word_pair_hash[word] = words_array[index + 1]
  end
end

$while = word_pair_hash["while"]
$print = word_pair_hash["print"]
$pause = word_pair_hash["pause"]
$def = word_pair_hash["def"]
$end = word_pair_hash["end"]
$if = word_pair_hash["if"]
$else_if = word_pair_hash["elseif"]
$else = word_pair_hash["else"]
$false = word_pair_hash["false|true"].split("|")[0]
$true = word_pair_hash["false|true"].split("|")[1]
$not = word_pair_hash["not"]
$and = word_pair_hash["and"]
$or = word_pair_hash["or"]

class TestArithmetic < Test::Unit::TestCase
  def test_addition
    assert_equal(3, LangParser.new.calc_test("1 + 2"))
    assert_equal(3, LangParser.new.calc_test("(1 + 2)"))
    assert_equal(3, LangParser.new.calc_test("((1 + 2))"))

    assert_equal(6, LangParser.new.calc_test("1 + 2 + 3"))
    assert_equal(6, LangParser.new.calc_test("(1 + 2) + 3"))
    assert_equal(6, LangParser.new.calc_test("((1 + 2) + 3)"))
    assert_equal(10, LangParser.new.calc_test("((1 + 2) + 3) + 4"))
    assert_equal(10, LangParser.new.calc_test("4 + ((3) + (2 + 1))"))
  end

  def test_subtraction
    assert_equal(1, LangParser.new.calc_test("2 - 1"))
    assert_equal(-3, LangParser.new.calc_test("(-2) - 1"))
    assert_equal(1, LangParser.new.calc_test("(2 - 1)"))
    assert_equal(1, LangParser.new.calc_test("((2 - 1))"))

    assert_equal(0, LangParser.new.calc_test("3 - 2 - 1"))
    assert_equal(0, LangParser.new.calc_test("(3 - 2) - 1"))
    assert_equal(0, LangParser.new.calc_test("((3 - 2)) - 1"))
    assert_equal(2, LangParser.new.calc_test("(4 - (3 - 2)) - 1"))
    assert_equal(2, LangParser.new.calc_test("(4 - ((3) - 2)) - 1"))
    assert_equal(4, LangParser.new.calc_test("4 - (((3) - 2) - 1)"))
  end

  def test_multiply
    assert_equal(2, LangParser.new.calc_test("2 * 1"))
    assert_equal(2, LangParser.new.calc_test("1 * 2"))
    assert_equal(2, LangParser.new.calc_test("1 * (2)"))
    assert_equal(2, LangParser.new.calc_test("(1) * (2)"))

    assert_equal(6, LangParser.new.calc_test("(1) * (2 * 3)"))
    assert_equal(6, LangParser.new.calc_test("(1 * 2 * 3)"))
    assert_equal(6, LangParser.new.calc_test("(1 * 2) * 3"))
    assert_equal(18, LangParser.new.calc_test("(3) * 2 * (3)"))
    assert_equal(-6, LangParser.new.calc_test("(3) * (0 - 2) * (1)"))
  end

  def test_division
    assert_equal(2, LangParser.new.calc_test("2 / 1"))
    assert_equal(1, LangParser.new.calc_test("2 / 2"))
    assert_equal(0.5, LangParser.new.calc_test("1 / 2"))
    assert_equal(-0.5, LangParser.new.calc_test("-1 / 2"))
    assert_equal(-2.5, LangParser.new.calc_test("-5 / 2"))

    assert_equal(0, LangParser.new.calc_test("(-1 + 1) / 2"))
    assert_equal(1, LangParser.new.calc_test("(3 / (3 / 1)) / 1"))
    assert_equal(1, LangParser.new.calc_test("(3 / (3 / 1)) / (1)"))
    assert_equal(3, LangParser.new.calc_test("(3 / (3 / 1-1-1)) / (1)"))
  end
end

class TestLogic < Test::Unit::TestCase
  def test_logic
    assert_equal(true, LangParser.new.calc_test("#{$true}"))
    assert_equal(true, LangParser.new.calc_test("#{$true} #{$and} #{$true}"))
    assert_equal(true, LangParser.new.calc_test("#{$true} #{$or} #{$true}"))
    assert_equal(true, LangParser.new.calc_test("#{$true} #{$or} #{$false}"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} #{$false}"))

    assert_equal(false, LangParser.new.calc_test("#{$false}"))
    assert_equal(false, LangParser.new.calc_test("#{$false} #{$and} #{$false}"))
    assert_equal(false, LangParser.new.calc_test("#{$false} #{$and} #{$true}"))
    assert_equal(false, LangParser.new.calc_test("#{$not} #{$true}"))

    assert_equal(true, LangParser.new.calc_test("(#{$not} #{$false}) #{$and} #{$true}"))
    assert_equal(true, LangParser.new.calc_test("(#{$not} #{$false}) #{$or} #{$false}"))
    assert_equal(true, LangParser.new.calc_test("#{$true} #{$and} #{$true} #{$or} #{$false}"))

  end
end

class TestComparisons < Test::Unit::TestCase
  def test_comparisons
    assert_equal(true, LangParser.new.calc_test("1 < 2"))
    assert_equal(false, LangParser.new.calc_test("1 > 2"))
    assert_equal(true, LangParser.new.calc_test("1 < 2 #{$and} #{$true}"))
    assert_equal(false, LangParser.new.calc_test("1 > 2 #{$and} #{$true}"))
    assert_equal(false, LangParser.new.calc_test("1 > 2 + 3 #{$and} #{$true}"))
    assert_equal(true, LangParser.new.calc_test("1+2 < 2+2 #{$and} #{$true}"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 > 2 #{$and} #{$true}"))
    assert_equal(true, LangParser.new.calc_test(" #{$true} #{$and} #{$not} 1 > 2"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 > 2 #{$and} #{$true}"))

    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 > 2 #{$and} #{$true} #{$or} #{$false}"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 > 2 #{$and} (#{$true} #{$or} #{$false})"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 > 2 #{$and} #{$false} #{$or} #{$true} #{$and} #{$true}"))

    assert_equal(true, LangParser.new.calc_test(" 1 == 1"))
    assert_equal(false, LangParser.new.calc_test(" 1 == 2"))
    assert_equal(true, LangParser.new.calc_test(" #{$not} 1 == 2"))
    assert_equal(false, LangParser.new.calc_test(" #{$not} 1 == 1"))

    assert_equal(true, LangParser.new.calc_test(" 1 <= 1"))
    assert_equal(false, LangParser.new.calc_test(" 3 <= 2"))
    assert_equal(true, LangParser.new.calc_test(" 1 <= 2"))

    assert_equal(true, LangParser.new.calc_test(" 1 >= 1"))
    assert_equal(true, LangParser.new.calc_test(" 3 >= 2"))
    assert_equal(false, LangParser.new.calc_test(" 1 >= 2"))
  end
end

class TestIf < Test::Unit::TestCase
  def test_if
    assert_equal(2, LangParser.new.calc_test("  #{$if} #{$true}
                                                  1+1
                                                #{$end}"))

    assert_equal(2, LangParser.new.calc_test("  #{$if} 3 == 3
                                                  1+1
                                                #{$end}"))

    assert_equal(nil, LangParser.new.calc_test("#{$if} 3 == 2
                                                  1+1
                                                #{$end}"))
  end
end
class TestVariables < Test::Unit::TestCase
  def test_variables
    assert_equal(1, LangParser.new.calc_test("x = 1
                                              x"))

    assert_equal(1, LangParser.new.calc_test("x = 1
                                              x
                                              x"))

    assert_equal(1, LangParser.new.calc_test("x = 1
                                              x
                                              x + 1
                                              x"))

    assert_equal(3, LangParser.new.calc_test("x = 1
                                              x + 2"))

    assert_equal(2, LangParser.new.calc_test("x = 1
                                              x = 2
                                              x"))

    assert_equal(5, LangParser.new.calc_test("x = 1 + 2
                                              x + 2"))

    assert_equal(5, LangParser.new.calc_test("x = 1 + 2
                                              x = x + 2
                                              x"))
  end
end

class TestFunction < Test::Unit::TestCase
  def test_function
    assert_equal(nil, LangParser.new.calc_test(" #{$def} foo()
                                                  5+5
                                                #{$end}"))

    assert_equal(10, LangParser.new.calc_test(" #{$def} foo()
                                                  5+5
                                                #{$end}
                                                foo()"))

    assert_equal(10, LangParser.new.calc_test(" #{$def} boo()
                                                  a = 5
                                                  a
                                                #{$end}
                                                b = 5 + boo()
                                                b"))
  end
end

class TestLoop < Test::Unit::TestCase
  def test_while
    assert_equal(WhileLoopNode, LangParser.new.calc_test("x = 5
                                                      #{$while} x < 10
                                                          x = x + 1
                                                      #{$end}"))

    assert_equal(10, LangParser.new.calc_test("x = 5
                                                      #{$while} x < 10
                                                          x = x + 1
                                                      #{$end}
                                                      x"))

    assert_equal(-10, LangParser.new.calc_test("x = 0
                                                      #{$while} x > -10
                                                          x = x - 1
                                                      #{$end}
                                                      x"))

    # assert_equal(0, LangParser.new.calc_test("x = 10
    #                                                   #{$while} -x < 0     # fundera på negering av variabler
    #                                                       x = x + 1
    #                                                   #{$end}
    #                                                   x"))
  end
end

class TesCompactIf < Test::Unit::TestCase
  def test_CompactIf
    assert_equal(4, LangParser.new.calc_test("x = 4
                                              #{$if} 7 <= 10 #{$and} > 5
                                                x
                                              #{$end}"))

    assert_equal(8, LangParser.new.calc_test("x = 8
                                              #{$if} x < 10 #{$and} > 5
                                                x
                                              #{$end}"))

    assert_equal(nil, LangParser.new.calc_test("x = 2
                                              #{$if} x <= 10 #{$and} >= 5
                                                x
                                              #{$end}"))
  end
end

class TestPrograms < Test::Unit::TestCase
  def test_fibonacci
    program = "
a = 1
b = 1

#{$def} fib(x)
  #{$if} 2 < x

    temp = a + b
    a = b
    b = temp

    fib(x - 1)
  #{$else}
    b
  #{$end}
#{$end}

fib(11)
"
    assert_equal(89, LangParser.new.calc_test(program))
  end

  def test_func_with_while
    program = "
x = 1

#{$def} foo(bar)
  #{$while} bar < 20
    #{$print} bar
    bar = bar + 1
  #{$end}
#{$end}

foo(x)
"
    assert_equal(WhileLoopNode, LangParser.new.calc_test(program))
  end

  def test_func_with_while_return_value
    program = "
x = 1

#{$def} foo(bar)
  y = 0
  #{$while} bar < 20
    #{$print} bar
    bar = bar + 1
    y = bar
  #{$end}
  #{$print} y
  y
#{$end}

foo(x)
"
    assert_equal(20, LangParser.new.calc_test(program))
  end
end
