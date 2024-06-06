# Error Handler, imported by RDParse.
class ErrorHandler
  class ParseError < RuntimeError
  end

  def self.convert_regex_sensitive_token(token, token_list)
    token = token_list['end'] if token == :STOP
    token = "#{token_list['(not|!)'].split('|')[0][1..]}" if token == :NOT
    token = "#{token_list['(and|&&)'].split('|')[0][1..]}" if token == :AND
    token = "#{token_list['(or|\|\|)'].split('|')[0][1..]}" if token == :OR
    token = '[(]' if token == '('
    token = '[)]' if token == ')'
    token = '[+]' if token == '+'
    token = '[-]' if token == '-'
    token = '[*]' if token == '*'
    token = '[/]' if token == '/'
    token
  end

  def self.translate_tokens_array(array, token_list)
    result = []
    array.each do |token|
      token = convert_regex_sensitive_token(token, token_list)
      result << token unless token.is_a?(Symbol)
      result << token_list[token.to_s.downcase] if token.is_a?(Symbol)
    end
    result
  end

  def self.find_surrounding_code(problem_pos, tokens)
    tokens_before_problem = []
    temp = problem_pos
    while temp >= 0
      tokens_before_problem << tokens[temp]
      temp -= 1
    end
    tokens_before_problem.reverse
  end

  def self.find_faulty_line(pos, file_string, tokens, token_list)
    tokens_before_problem = find_surrounding_code(pos - 1, tokens)
    file_as_array_without_whitespaces = translate_tokens_array(tokens_before_problem, token_list)

    pattern = file_as_array_without_whitespaces.join('\s*')
    regex = Regexp.new(pattern)

    # Remove comments, replace entire comment lines with "\n" to perserve num_lines
    cleaned_string = file_string.gsub(/^;;.*/, "\n")
    cleaned_string = cleaned_string.gsub(/;;.*/, '')

    match_data = regex.match(cleaned_string)
    num_lines = match_data[0].count("\n") + 1 unless NilClass # TODO: Find out what causes these edge cases

    problem = tokens[pos]
    line_msg = "There is a problem on line #{num_lines}"
    line_msg = "Couldn't precise the exact line" if num_lines.is_a?(NilClass) # TODO: Find out edge cases

    if tokens_before_problem[-1] == :PRINT
      raise ParseError, "#{line_msg} with the <#{token_list['print']}> statement, needs something to print."
    elsif tokens_before_problem[-1] == :PAUSE
      raise ParseError, "#{line_msg} with the <#{token_list['pause']}> statement, pause needs a numeric argument."
    elsif problem == :STOP
      raise ParseError, "#{line_msg}. Found <#{token_list['end']}>\nEmpty if-statements and functions are not allowed"
    else
      raise ParseError, "#{line_msg}. Found <#{problem}>"
    end
  end
end
