require_relative 'basenodes'

def set_up_scope_header
  result = "<#{ScopeManager.scope_lvl}>   "
  result += '++--++--' * (ScopeManager.scope_lvl + 1) + ' '
  result
end

###################### Variable Nodes

class VariableCallNode < Node
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Variable #{@name} is now  #{@value}"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def to_s
    @name
  end

  def evaluate
    @value = ScopeManager.lookup_var(@name)
    create_tree_entry if PRINT_TREE_FLAG
    return @value
  end
end

class VariableDecNode < Node
  attr_accessor :name

  def initialize(name, value)
    super(value)
    @name = name
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Variable #{@name} is now  #{@value}"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def to_s
    "#{@name} = #{@value}"
  end

  def evaluate
    ScopeManager.add_to_current_scope(name, @value)
    create_tree_entry if PRINT_TREE_FLAG
    self
  end
end

class ArrayCallNode < Node
  def initialize(array, index)
    super(array)
    @index = index.to_i
  end

  def evaluate
    arr = ScopeManager.lookup_var(@value)
    if @index > arr.size - 1
      raise ArgumentError, "You are trying to access an out of bounds index. Here -> #{@value}[#{@index}]"
    end
    @value = arr[@index]
    @value
  end
end

###################### Function Nodes

class FunctionDecNode < Node
  def initialize(node, value)
    super(value)
    @name = node
    @args = node.args
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Function #{@name} declared"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def to_s
    "#{@name} = #{@value}"
  end

  def evaluate
    ScopeManager.add_func_to_global_scope(@name, @value, @args)
    create_tree_entry if PRINT_TREE_FLAG
    return nil
  end
end

class FuncCallNode < Node
  attr_accessor :name, :args

  def initialize(name, args)
    @name = name
    @args = args
  end

  def to_s
    if @args == NilClass
      "#{name}()"
    else
      "#{name}(#{@args})"
    end
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Function #{@name} is called"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    func = ScopeManager.lookup_func(@name)

    function_body = func[0]
    function_param = func[1]

    ScopeManager.increment_scope_level

    if function_param.is_a?(ArrayNode)
      function_param.each do |val, index|
        function_param[index] = VariableDecNode.new(function_param[index].name, @args[index])
        function_param[index].evaluate
      end
    end

    func_return_value = function_body.evaluate

    ScopeManager.decrement_scope_level

    # If function return value is an "Assign" then we declare that variable in the global scope.
    # This should be a ScopeManager method, add_variable_to_global_scope is missing.
    old_scope_lvl = ScopeManager.scope_lvl
    if func_return_value.is_a?(VariableDecNode)
      ScopeManager.scope_lvl = 0
      func_return_value.evaluate
      ScopeManager.scope_lvl = old_scope_lvl
    end

    create_tree_entry if PRINT_TREE_FLAG
    return func_return_value
  end
end

###################### If Statement Nodes

class IfNode < Node
  attr_accessor :argument

  def initialize(argument, node)
    @argument, @node = argument, node
  end

  def to_s
    "If #{argument}"
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "If statement #{@argument} is used"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    @value = @node.evaluate
    create_tree_entry if PRINT_TREE_FLAG
    @value
  end
end

class ElseifNode < Node
  attr_accessor :argument

  def initialize(argument, node)
    @argument, @node = argument, node
  end

  def to_s
    'Else'
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Elseif statement is used. #{@argument}"
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    @value = @node.evaluate
    create_tree_entry if PRINT_TREE_FLAG
    @value
  end
end

class ElseNode < Node
  attr_accessor :argument, :node

  def initialize(node)
    @node = node
    @argument = BoolNode.new(ScopeManager.true_value)
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Else statement is used."
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    @value = @node.evaluate
    create_tree_entry if PRINT_TREE_FLAG
    @value
  end
end

class IfCompStmtNode < Node
  def initialize(*nodes)
    @nodes = nodes.flatten
  end

  def evaluate
    @nodes.each do |node|
      if node.argument.evaluate
        return node.evaluate
      end
    end
    return nil
  end
end

###################### Loop Nodes

class WhileLoopNode < Node
  attr_accessor :condition

  def initialize(condition, statement)
    @condition = condition
    super(statement)
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "While Loop ran with #{@counter} iterations."
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    @counter = 0
    while @condition.evaluate
      @value.evaluate
      @counter += 1
    end
    create_tree_entry if PRINT_TREE_FLAG
    self.class
  end
end

###################### Built-in Functions

class PrintNode
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Printed #{@value}."
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    if @value.evaluate.is_a?(ArrayNode)
      print "Array #{@value.name}: "     unless TEST_UNIT_ACTIVE
      puts @value.evaluate               unless TEST_UNIT_ACTIVE
    else
      puts @value.evaluate               unless TEST_UNIT_ACTIVE
    end
    create_tree_entry if PRINT_TREE_FLAG
    self.class
  end
end

class PauseNode < Node
  def initialize(value)
    super(value)
  end

  def create_tree_entry
    result = set_up_scope_header
    result += "Paused for #{@value} seconds."
    TREE_ARRAY << result unless TREE_ARRAY[-1] == result
  end

  def evaluate
    # TODO: Create an Error Handler class... Needs to use rdparses functions here for a more helpful msg.
    raise SyntaxError, 'Pause needs a numeric argument.' unless @value.evaluate.is_a?(Numeric)

    @value = 0 if @value.evaluate.negative?
    create_tree_entry if PRINT_TREE_FLAG
    sleep @value.evaluate
  end
end
