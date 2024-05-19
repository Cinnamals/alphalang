# This file is called rdparse.rb because it implements a Recursive
# Descent Parser. Read more about the theory on e.g.
# http://en.wikipedia.org/wiki/Recursive_descent_parser

# 2010-02-11 New version of this file for the 2010 instance of TDP007
#   which handles false return values during parsing, and has an easy way
#   of turning on and off debug messages.
# 2014-02-16 New version that handles { false } blocks and :empty tokens.

require 'logger'

class Rule

  # A rule is created through the rule method of the Parser class, like this:
  #   rule :term do
  #     match(:term, '*', :dice) {|a, _, b| a * b }
  #     match(:term, '/', :dice) {|a, _, b| a / b }
  #     match(:dice)
  #   end

  Match = Struct.new :pattern, :block

  def initialize(name, parser, debug_bool)
    @logger = parser.logger
    @debug_mode = debug_bool
    # The name of the expressions this rule matches
    @name = name
    # We need the parser to recursively parse sub-expressions occurring
    # within the pattern of the match objects associated with this rule
    @parser = parser
    @matches = []
    # Left-recursive matches
    @lrmatches = []
  end

  # Add a matching expression to this rule, as in this example:
  #   match(:term, '*', :dice) {|a, _, b| a * b }
  # The arguments to 'match' describe the constituents of this expression.
  def match(*pattern, &block)
    match = Match.new(pattern, block)
    # If the pattern is left-recursive, then add it to the left-recursive set
    if pattern[0] == @name
      pattern.shift
      @lrmatches << match
    else
      @matches << match
    end
  end

  def parse
    # Try non-left-recursive matches first, to avoid infinite recursion
    match_result = try_matches(@matches)
    return nil if match_result.nil?
    loop do
      result = try_matches(@lrmatches, match_result)
      return match_result if result.nil?
      match_result = result
    end
  end

  private

  # Try out all matching patterns of this rule
  def try_matches(matches, pre_result = nil)
    match_result = nil
    # Begin at the current position in the input string of the parser
    start = @parser.pos
    matches.each do |match|
      # pre_result is a previously available result from evaluating expressions
      result = pre_result.nil? ? [] : [pre_result]

      # We iterate through the parts of the pattern, which may be e.g.
      #   [:expr,'*',:term]
      match.pattern.each_with_index do |token,index|

        # If this "token" is a compound term, add the result of
        # parsing it to the "result" array
        if @parser.rules[token]
          result << @parser.rules[token].parse
          if result.last.nil?
            result = nil
            break
          end
          @logger.debug("Matched '#{@name} = #{match.pattern[index..-1].inspect}'") if @debug_mode
        else
          # Otherwise, we consume the token as part of applying this rule
          nt = @parser.expect(token)
          if nt
            result << nt
            if @lrmatches.include?(match.pattern) then
              pattern = [@name]+match.pattern
            else
              pattern = match.pattern
            end
            @logger.debug("Matched token '#{nt}' as part of rule '#{@name} <= #{pattern.inspect}'") if @debug_mode
          else
            result = nil
            break
          end
        end # pattern.each
      end # matches.each
      if result
        if match.block
          match_result = match.block.call(*result)
        else
          match_result = result[0]
        end
        @logger.debug("'#{@parser.string[start..@parser.pos-1]}' matched '#{@name}' and generated '#{match_result.inspect}'") unless match_result.nil? if @debug_mode
        break
      else
        # If this rule did not match the current token list, move
        # back to the scan position of the last match
        @parser.pos = start
      end
    end

    return match_result
  end
end

class Parser
  attr_accessor :pos
  attr_reader :rules, :string, :logger

  class ParseError < RuntimeError
  end

  def initialize(language_name, debug_bool, locale, &block)
    @debug_mode = debug_bool
    @logger = Logger.new(STDOUT) if @debug_mode
    @lex_tokens = []
    @rules = {}
    @start = nil
    @language_name = language_name
    @file_string = ''

    create_tokens_from_locale(locale)

    false_value = @token_list['(false|true)'].split('|')[0]# Hacky solution to convoluted tokens
    true_value = @token_list['(false|true)'].split('|')[1]
    true_value = true_value[0..-2]
    false_value = false_value[1..]

    ScopeManager.new(true_value, false_value) # Hacky solution to convoluted tokens

    instance_eval(&block)
  end

  # Recreate the tokenlist using the chosen locale file
  def create_tokens_from_locale(locale)
    if locale == 'default'
      lang_file = File.read("#{LOCALES_PATH}/#{locale}")
      token_pairs = File.readlines("#{LOCALES_PATH}/#{lang_file}")
    else
      token_pairs = File.readlines("#{LOCALES_PATH}/#{locale}")
    end
    @token_list = Hash.new
    token_pairs.each do |pair|
      default_value, locale_value = pair.split(' ')
      @token_list[default_value] = locale_value
    end
  end

  # Tokenize the string into small pieces
  def tokenize(string)
    @tokens = []
    @string = string.clone
    until string.empty?
      # Unless any of the valid tokens of our language are the prefix of
      # 'string', we fail with an exception
      raise ParseError, "unable to lex '#{string}" unless @lex_tokens.any? do |tok|
        match = tok.pattern.match(string)
        # The regular expression of a token has matched the beginning of 'string'
        if match
          @logger.debug("Token #{match[0]} consumed as #{match[0]}") if @debug_mode
          # Also, evaluate this expression by using the block
          # associated with the token
          @tokens << tok.block.call(match.to_s) if tok.block
          # consume the match and proceed with the rest of the string
          string = match.post_match
          true
        else
          # this token pattern did not match, try the next
          false
        end # if
      end # raise
    end # until
  end

  def convert_regex_sensitive_token(token)
      token = @token_list['end'] if token == :STOP    # fulhack pga :END påstods inte funka för länge sen
      token = '[(]' if token == '('
      token = '[)]' if token == ')'
      token = '[+]' if token == '+'
      token = '[-]' if token == '-'
      token = '[*]' if token == '*'
      token = '[/]' if token == '/'
      token = "#{@token_list['(not|!)'].split('|')[0][1..]}" if token == :NOT
      token = "#{@token_list['(and|&&)'].split('|')[0][1..]}" if token == :AND
      token = "#{@token_list['(or|\|\|)'].split('|')[0][1..]}" if token == :OR
      token
  end

  def translate_tokens_array(array)
    result = []
    array.each do |token|
      token = convert_regex_sensitive_token(token)
      result << token unless token.is_a?(Symbol)
      result << @token_list[token.to_s.downcase] if token.is_a?(Symbol)
    end
    result
  end

  def find_surrounding_code(problem_pos)
    tokens_before_problem = []
    temp = problem_pos
    while temp >= 0
      tokens_before_problem << @tokens[temp]
      temp -= 1
    end
    tokens_before_problem.reverse
  end

  def find_faulty_line
    tokens_before_problem = find_surrounding_code(@max_pos - 1)
    file_as_array_without_whitespaces = translate_tokens_array(tokens_before_problem)

    pattern = file_as_array_without_whitespaces.join('\s*')
    regex = Regexp.new(pattern)

    cleaned_string = @file_string.gsub(/;;.*/, '')

    match_data = regex.match(cleaned_string)
    num_lines = match_data[0].count("\n") + 1

    problem = @tokens[@max_pos]
    problem = @token_list[problem.to_s.downcase] unless @token_list[problem.to_s.downcase].is_a?(NilClass)

    raise ParseError, "There is a problem around line #{num_lines}. Found <#{problem}>"
  end

  def parse(string)
    # First, split the string according to the "token" instructions given.
    # Afterwards @tokens contains all tokens that are to be parsed.
    @file_string = string
    tokenize(string)

    # These variables are used to match if the total number of tokens
    # are consumed by the parser
    @pos = 0
    @max_pos = 0
    @expected = []
    # Parse (and evaluate) the tokens received
    result = @start.parse
    # If there are unparsed extra tokens, signal error
    if @pos != @tokens.size

      if @tokens[@max_pos] == '(' || @tokens[@max_pos] == ')'
        raise ParseError, 'Mismatched parenthesis! In Emacs: M-x check-parens RET'
      end

      # raise ParseError, "Parse error. expected: '#{@expected.join(', ')}', found '#{@tokens[@max_pos]}'"
      return find_faulty_line
    end
    return result
  end

  def next_token
    @pos += 1
    return @tokens[@pos - 1]
  end

  # Return the next token in the queue
  def expect(tok)
    return tok if tok == :empty
    t = next_token
    if @pos - 1 > @max_pos
      @max_pos = @pos - 1
      @expected = []
    end
    return t if tok === t
    @expected << tok if @max_pos == @pos - 1 && !@expected.include?(tok)
    return nil
  end

  def to_s
    "Parser for #{@language_name}"
  end

  private

  LexToken = Struct.new(:pattern, :block)

  def token(pattern, &block)
    @lex_tokens << LexToken.new(Regexp.new('\\A' + @token_list[pattern.source]), block)
  end

  def start(name, &block)
    rule(name, &block)
    @start = @rules[name]
  end

  def rule(name,&block)
    @current_rule = Rule.new(name, self, @debug_mode)
    @rules[name] = @current_rule
    instance_eval &block # In practise, calls match 1..N times
    @current_rule = nil
  end

  def match(*pattern, &block)
    # Basically calls memberfunction "match(*pattern, &block)
    @current_rule.send(:match, *pattern, &block)
  end

end