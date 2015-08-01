require_relative 'formula'

class Parser
  LPAREN = '('
  RPAREN = ')'
  NOT = '!'
  AND = '&'
  OR = '|'
  IMPLIES = '->'

  MAX_PREC = 10

  PRECEDENCE = {
    NOT => 1,
    AND => 2,
    OR => 3,
    IMPLIES => 4
  }

  def initialize
    @index = 0
  end

  def parse(s)
    @input = s.chomp()

    @back_index = 0
    @index = 0

    if @input.length == 0
      raise "Empty input"
    end

    t = parse_to_prec(MAX_PREC)

    return t
  end

  def parse_to_prec(prec)
    t1 = read_one_term()
    @back_index = @index

    #read an operator
    while !end_of_input() do
      s = next_token()

      # if s is a closing bracket, then t1 is the largest subterm
      # that can be read
      if s == RPAREN
        @index = @back_index
        return t1
      end

      #otherwise, the next token should be an operator
      op = get_operator(s)
      pr = PRECEDENCE[op]

      #only read further if the precedence of the new operator is no greater than prec
      if (pr > prec)
        @index = @back_index
        return t1
      else #op has lower precedence
        t2 = parse_to_prec(pr)

        if op == AND
          t1 = Conjunction.new([t1, t2])
        elsif op == OR
          t1 = Disjunction.new([t1, t2])
        elsif op == IMPLIES
          t1 = Implication.new(t1, t2)
        end
      end
    end

    return t1
  end

  def read_one_term
    s = next_token()

    if s == LPAREN
      t = parse_to_prec(MAX_PREC)
      read(RPAREN)
      return t
    end

    if s == NOT
      t = parse_to_prec(PRECEDENCE[NOT])
      return Negation.new(t)
    end

    t = Variable.new(s)

    return t
  end

  def end_of_input
    @index == @input.length
  end

  def get_operator(s)
    if ![AND, OR, IMPLIES].include?(s)
      raise "Expected one of \"&\" or \"|\" or \"->\""
    end

    return s
  end

  def next_token
    if @input[@index] == '('
      @index += 1
      read_white_space()
      return LPAREN
    end

    if @input[@index] == ')'
      @index += 1
      read_white_space()
      return RPAREN
    end

    if @input[@index] == '&'
      @index += 1
      read_white_space()
      return AND
    end

    if @input[@index] == '|'
      @index += 1
      read_white_space()
      return OR
    end

    if @input[@index] == '-' && @input[@index+1] == '>'
      @index += 2
      read_white_space()
      return IMPLIES
    end

    if @input[@index] == '!'
      @index += 1
      read_white_space()
      return NOT
    end

    return read_literal()
  end

  def read(s)
    t = read_next(s.length)

    if t != s
      raise "Expected #{s} at character number #{@index - s.length}"
    end
  end

  def read_white_space
    while !end_of_input() && is_white_space() do
      @index += 1
    end
  end

  def is_white_space
    @input[@index] == ' '
  end

  def is_alphanum
    is_alpha(@input[@index]) || is_num(@input[@index])
  end

  def is_alpha(char)
    (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z')
  end

  def is_num(char)
    char >= '0' && char <= '9'
  end

  def is_operator(char)
    ['.', '+', '-', '>'].include?(char)
  end

  def read_next(n)
    if (@index + n > @input.length)
      raise "Unexpected end of input"
    end

    s = @input[@index..@index+n-1].strip
    @index += n

    read_white_space()

    return s
  end

  def read_literal()
    start = @index

    while !end_of_input && is_alphanum() do
      @index += 1
    end

    s = @input[start..@index-1]

    read_white_space()

    return s
  end
end