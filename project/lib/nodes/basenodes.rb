###################### Base Nodes

class Node
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def to_s
    @value
  end

  def evaluate
    @value.evaluate
  end
end

class NumberNode < Node
  def initialize(value)
    super(value)
  end

  def evaluate
    if @value.include?('.')
      @value.to_f
    else
      @value.to_i
    end
  end
end

class BoolNode < Node
  def initialize(value)
    @value = true if value == ScopeManager.true_value
    @value = false if value == ScopeManager.false_value
  end

  def to_s
    @value.to_s
  end

  def evaluate
    @value
  end
end

class StringNode < Node
  def initialize(value)
    if value.is_a?(String)
      super
    else
      super(value.join(' '))
    end
  end

  def evaluate
    @value = @value.gsub(' ,', ',') # stupid
    @value = @value.gsub(' .', '.') # stupid
  end
end

###################### Logic Gate Nodes

class AndNode < Node
  def initialize(lhs, rhs)
    @lhs, @rhs = lhs, rhs
    return unless @rhs.class.method_defined?(:lhs)

    @rhs.lhs = @lhs.lhs if @rhs.lhs == nil
  end

  def to_s
    "#{@lhs} and #{@rhs}"
  end

  def evaluate
    @lhs.evaluate && @rhs.evaluate
  end
end

class OrNode < Node
  def initialize(lhs, rhs)
    @lhs, @rhs = lhs, rhs
    return unless @rhs.class.method_defined?(:lhs)

    @rhs.lhs = @lhs.lhs if @rhs.lhs == nil
  end

  def to_s
    "#{@lhs} or #{@rhs}"
  end

  def evaluate
    @lhs.evaluate || @rhs.evaluate
  end
end

class NotNode < Node
  def initialize(node)
    @node = node
  end

  def to_s
    "not #{@node}"
  end

  def evaluate
    not @node.evaluate
  end
end

###################### Operation Nodes

class CompareNode < Node
  attr_accessor :lhs, :op, :rhs

  def initialize(lhs, op, rhs)
    @lhs, @op, @rhs = lhs, op, rhs
  end

  def to_s
    "#{@lhs} #{@op} #{@rhs}"
  end

  def evaluate
    @value = @lhs.evaluate.send(@op, @rhs.evaluate)
  end
end

class BinaryOperationNode < Node
  attr_accessor :lhs, :op, :rhs

  def initialize(lhs, op, rhs)
    super(op)
    @lhs, @op, @rhs = lhs, op, rhs
  end

  def to_s
    "#{@lhs} #{@op} #{@rhs}"
  end

  def evaluate
    if @rhs.evaluate.is_a?(ArrayNode) && @op == '+'
      return @value = @rhs.evaluate + @lhs.evaluate
    end

    if @op == '/'
      @value = @lhs.evaluate.to_f.send(@op, @rhs.evaluate)
    else
      @value = @lhs.evaluate.send(@op, @rhs.evaluate)
    end
  end
end

###################### Array / Data Structure Nodes

class ArrayNode < Node
  attr_accessor :lhs, :rhs

  def initialize(lhs, rhs)
    @lhs, @rhs = lhs, rhs

    if @rhs == NilClass
      @value = [@lhs]
    else
      result = [@lhs]
      @rhs.each do |element|
        result << element
      end
      @value = result
    end
  end

  def display_on_new_line
    puts @value
  end

  def display_on_one_line
    puts @value.join(', ')
  end

  def to_s
    @value.join(', ')
  end

  def +(value)
    @value.append(value)
    self
  end

  def -(value)
    @value = @value.reject { |v| v.evaluate == value }
    self
  end

  def [](index)
    @value[index]
  end

  def []=(index, value)
    @value[index] = value
  end

  def size
    @value.size
  end

  def each
    @value.each_with_index do |val, index|
      yield val, index
    end
  end

  def evaluate
    self
  end
end

###################### Root Program Node

class CompStmtNode < Node
  def initialize(stmt_compstmt)
    super
    @comp_statements = stmt_compstmt
  end

  def evaluate
    @comp_statements[0].evaluate
    @comp_statements[1].evaluate
  end
end
