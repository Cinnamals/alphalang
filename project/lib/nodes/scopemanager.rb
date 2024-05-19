require_relative 'stmtnodes'

####################################################

class ScopeManager
  def initialize(true_value, false_value)
    @@true_value = true_value
    @@false_value = false_value
    @@scopes = [{}]
    @@scope_lvl = 0
  end

  def self.true_value
    @@true_value
  end

  def self.false_value
    @@false_value
  end

  def self.scope_lvl
    @@scope_lvl
  end

  def self.scope_lvl=(value)
    @@scope_lvl = value
  end

  def self.lookup_var(name)
    temp_scope_lvl = @@scope_lvl
    while temp_scope_lvl >= 0
      if !@@scopes[temp_scope_lvl].key?(name)
        temp_scope_lvl -= 1
      else
        return @@scopes[temp_scope_lvl][name]
      end
    end
    raise SyntaxError, "Variable '#{name}' is not defined" unless @value
  end

  def self.increment_scope_level
    @@scope_lvl += 1
    @@scopes.push({})
  end

  def self.decrement_scope_level
    @@scope_lvl -= 1
    @@scopes.pop
  end

  def self.lookup_func(name)
    raise SyntaxError, "Function '#{name}' is not defined" if @@scopes[0][name].is_a?(NilClass)
    return @@scopes[0][name]
  end

  def self.add_to_current_scope(name, value)
    if name.is_a?(String)
      @@scopes[@@scope_lvl][name] = value.evaluate
    else
      @@scopes[@@scope_lvl][name.name] = value.evaluate
    end
  end

  def self.add_func_to_global_scope(name, value, args)
    @@scopes[0][name.name] = [value, args]
  end
end
