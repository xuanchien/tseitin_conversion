require_relative 'parser'

class VariableFactory
  def initialize(unique_prefix = '')
    @counter = 1
    @unique_prefix = unique_prefix
  end

  def get_variable
    v = Variable.new(@unique_prefix + @counter.to_s)
    @counter += 1

    return v
  end
end

class TseitinConversion
  def to_cnf(formula)
    return Conjunction.new(to_cnf_clauses(formula))
  end

  def to_cnf_clauses(formula)
    f = VariableFactory.new('a')
    t = formula.derivation_tree()

    clauses = []
    root = tseitin(t, f, clauses)
    res = [root]

    #conjoin all conjuctions
    clauses.each do |c|
      if c.is_a?(Conjunction)
        res += c.subf
      else
        res << c
      end
    end

    return res
  end

  def tseitin(tree, factory, clauses)
    if tree.is_a?(Variable)
      return tree.clone()
    end

    v = factory.get_variable()
    new_vars_for_subf = []
    tree.get_children().each do |e|
      new_vars_for_subf << tseitin(e, factory, clauses)
    end

    new_lit = tree.encode_tseitin(v, new_vars_for_subf)

    clauses << new_lit

    return v
  end
end

if ARGV.length == 0
  puts("Please specify input file")
  exit
end

input_file = ARGV.first

text = File.open(input_file, "r").read.chomp

conversion = TseitinConversion.new
formula = Parser.new.parse(text)
clauses = conversion.to_cnf_clauses(formula)

output_file = File.basename(input_file, ".txt")

File.open("#{output_file}_result.txt", "w") do |f|
  f.puts clauses.map{|c| "(#{c.to_s})" }.join(' & ')
end

puts "DONE"
