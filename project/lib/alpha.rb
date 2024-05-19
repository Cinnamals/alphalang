require_relative './nodes/scopemanager'

class LangParser
  def initialize(locale = 'default', debug_mode = false)
    @langParser = Parser.new('lang parser', debug_mode, locale) do
      token(/;;.*$/)
      token(/while/) { |_| :WHILE }
      token(/print/) { |_| :PRINT }
      token(/pause/) { |_| :PAUSE }
      token(/def/) { |_| :DEF }
      token(/end/) { |_| :STOP }
      token(/if/) { |_| :IF }
      token(/elseif/) { |_| :ELSEIF }
      token(/else/) { |_| :ELSE }
      token(/(false|true)/) { |m| m }
      token(/(==|<=|>=)/) { |m| m }
      token(/(not|!)/) { |_| :NOT }
      token(/(and|&&)/) { |_| :AND }
      token(/(or|\|\|)/) { |_| :OR }
      token(/\s+/)
      token(/\d+/) { |m| m }
      token(/\w+/) { |m| m }
      token(/./) { |m| m }

      start :program do
        match(:comp_stmt)
        match(:terminal)
      end

      rule :terminal do
        match(/\n|;/)
      end

      rule :comp_stmt do
        match(:stmt, :comp_stmt) { |a, b| CompStmtNode.new([a, b]) }
        match(:stmt)
      end

      ###################### Statement Rules

      rule :stmt do
        match(:if_comp_stmt)
        match(:loop)
        match(:declaration)
        match(:builtin)
        match(:expr_stmt)
      end

      rule :loop do
        match(:while_stmt)
      end

      rule :declaration do
        match(:func_dec)
        match(:ass_stmt)
      end

      rule :builtin do
        match(:pause_stmt)
        match(:print_stmt)
      end

      ###################### If Statement Rules

      rule :if_comp_stmt do
        match(:if_stmt, :comp_elseif, :else_stmt, :STOP) { |a, b, c| IfCompStmtNode.new(a, b, c) }
        match(:if_stmt, :comp_elseif, :STOP) { |a, b| IfCompStmtNode.new(a, b) }
        match(:if_stmt, :else_stmt, :STOP) { |a, b| IfCompStmtNode.new(a, b) }
        match(:if_stmt, :STOP) { |a| IfCompStmtNode.new(a) }
      end

      rule :if_stmt do
        match(:IF, :expr_stmt, :comp_stmt) { |_, a, b| IfNode.new(a, b) }
      end

      rule :comp_elseif do
        match(:elseif_stmt, :comp_elseif) { |a, b| [a, b] }
        match(:elseif_stmt)
      end

      rule :elseif_stmt do
        match(:ELSEIF, :expr_stmt, :comp_stmt) { |_, a, b| ElseifNode.new(a, b) }
      end

      rule :else_stmt do
        match(:ELSE, :comp_stmt) { |_, b| ElseNode.new(b) }
      end

      ###################### Loop Rules

      rule :while_stmt do
        match(:WHILE, :expr_stmt, :comp_stmt, :STOP) { |_, a, b| WhileLoopNode.new(a, b) }
      end

      ###################### Variable and Function Declare Rules

      rule :func_dec do
        match(:DEF, :call_member, :comp_stmt, :STOP) { |_, name, value, _| FunctionDecNode.new(name, value) }
      end

      rule :ass_stmt do
        match(:member, '=', :expr) { |var, _, value, _| VariableDecNode.new(var, value) }
        match(:member, '=', :array_stmt) { |var, _, value| VariableDecNode.new(var, value) }
      end

      ###################### Built-In Function Rules

      rule :pause_stmt do
        match(:PAUSE, :expr) { |_, a| PauseNode.new(a) }
      end

      rule :print_stmt do
        match(:PRINT, :expr) { |_, a| PrintNode.new(a) }
      end

      ###################### Expression Rules

      rule :expr_stmt do
        match(:or_stmt)
        match(:and_stmt)
        match(:not_stmt)
        match(:expr)
      end

      rule :or_stmt do
        match(:expr, :OR, :expr_stmt) { |a, _, b| OrNode.new(a, b) }
      end

      rule :and_stmt do
        match(:expr, :AND, :expr_stmt) { |a, _, b| AndNode.new(a, b) }
      end

      rule :not_stmt do
        match(:NOT, :expr_stmt) { |_, b| NotNode.new(b) }
      end

      rule :expr do
        match(:expr, /(<|>)/, :expr) { |a, op, b| CompareNode.new(a, op, b) }
        match(/(<|>)/, :expr) { |op, b| CompareNode.new(nil, op, b) }
        match(:expr, /(<=|>=)/, :expr) { |a, op, b| CompareNode.new(a, op, b) }
        match(/(<=|>=)/, :expr) { |op, b| CompareNode.new(nil, op, b) }
        match(:expr, '==', :expr) { |a, op, b| CompareNode.new(a, op, b) }
        match(:expr, '+', :term) { |a, op, b| BinaryOperationNode.new(a, op, b) }
        match(:expr, '-', :term) { |a, op, b| BinaryOperationNode.new(a, op, b) }
        match(:term)
      end

      rule :term do
        match(:term, '*', :atom) { |a, op, b| BinaryOperationNode.new(a, op, b) }
        match(:term, '/', :atom) { |a, op, b| BinaryOperationNode.new(a, op, b) }
        match(:atom)
      end

      ###################### Data Types Rules

      rule :array_stmt do
        match('[', :arg_list, ']') { |_, array, _| array }
      end

      rule :arg_list do
        match(:expr, ',', :arg_list) { |a, _, b| ArrayNode.new(a, b) }
        match(:expr) { |a| ArrayNode.new(a, NilClass) }
      end

      rule :atom do
        match(:number)
        match(:boolean)
        match(:string)
        match(:call_member)
        match(:prio_stmt)
      end

      rule :number do
        match('-', /\d+/, '.', /\d+/) { |neg, a, dot, b| NumberNode.new(neg + a + dot + b) }
        match(/\d+/, '.', /\d+/) { |a, dot, b| NumberNode.new(a + dot + b) }
        match('-', /\d+/) { |neg, a| NumberNode.new(neg + a) }
        match(/\d+/) { |a| NumberNode.new(a) }
      end

      rule :boolean do
        match(ScopeManager.true_value) { |a| BoolNode.new(a) }
        match(ScopeManager.false_value) { |a| BoolNode.new(a) }
      end

      rule :string do
        match('"', :comp_string, '"') { |_, str, _| StringNode.new(str) }
      end

      # TODO: Figure out if  this is possible with char without messing too much with lexer
      rule :comp_string do
        match(:word, :comp_string) { |a, b| [a, b].flatten }
        match(:word)
      end

      rule :word do
        match(/\w/) { |m| m }
        match(/[,]/) { |m| m } # stupid
        match(/[.]/) { |m| m } # stupid
        match(/(==|<=|>=|=|[+]|-|[\/])/) { |m| m }
        # match(/\p{Punct}/) { |m| m } # Something fatal here. This eats PRINT and ==, everything.
      end

      rule :call_member do
        match(:member, '(', :arg_list, ')') { |var, _, args, _| FuncCallNode.new(var, args) }
        match(:member, '(', ')') { |var, _, _| FuncCallNode.new(var, NilClass) }
        match(:member, '[', '-', /\d+/, ']') { |var, _, neg, index, _| ArrayCallNode.new(var, (neg+index)) }
        match(:member, '[', /\d+/, ']') { |var, _, index, _| ArrayCallNode.new(var, index) }
        match(:member) { |var| VariableCallNode.new(var) }
      end

      rule :member do
        match(/[a-z]/)
      end

      rule :prio_stmt do
        match('(', :stmt, ')') { |_, a, _| a }
      end
    end
  end

  def parse_file(filename)
    file = File.read(filename)
    root = @langParser.parse file
    root = root.evaluate
    puts TREE_ARRAY
    root
  end

  def calc_test(str)
    root = @langParser.parse str
    root.evaluate
  end
end
