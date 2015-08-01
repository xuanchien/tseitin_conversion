#base class, other formula will be derived from this class
class Formula
  attr_accessor :subf
  def initialize(is_cnf = false)
    @is_cnf = is_cnf
  end

  def to_cnf
  end

  def clone
  end

  def derivation_tree
  end

  def get_children
  end

  def encode_tseitin
  end
end

class Conjunction < Formula
  def initialize(subformulas, is_cnf = false)
    super(is_cnf)
    @subf = subformulas
  end

  def to_s
    @subf.each do |f|
      f.to_s
    end.join(' & ')
  end

  def to_cnf
    return self if @is_cnf

    clauses = []

    if @subf.all? {|c| c.is_a?(Conjunction) }
      @subf.each do |c|
        clauses += c.to_cnf().subf
      end
    else
      @subf.each do |f1|
        f = f1.to_cnf()
        if f.is_a?(Conjunction)
          clauses += f.subf
        else
          clauses << f
        end
      end
    end

    #filter duplicates
    filtered = []

    clauses.each do |c|
      if !filtered.any? {|f| f.equals(c) }
        filtered << c
      end
    end

    return Conjunction.new(filtered.sort_by(&:to_s), true)
  end

  def encode_tseitin(new_var, subf)
    return Equivalence.new(new_var, Conjunction.new(subf)).to_cnf()
  end

  def get_children
    @subf
  end

  def derivation_tree
    if @subf.length < 1
      raise "Too few subformulas in a conjunction"
    elsif @subf.length == 1
      return @subf[0].derivation_tree()
    else
      return Conjunction.new(@subf.map{|e| e.derivation_tree })
    end
  end

  def equals(f)
    return false if !f.is_a?(Conjunction)

    @subf.zip(f.subf).all? {|c1, c2| c1.equals(c2)}
  end

  def clone
    return Conjunction.new(@subf.map{|f| f.clone()}, @is_cnf)
  end
end

class Disjunction < Formula
  def initialize(subformulas = [], is_cnf = false)
    super(is_cnf)
    @subf = subformulas
  end

  def to_s
    @subf.map(&:to_s).join(' | ')
  end

  def to_cnf
    return self if @is_cnf

    terms = []
    conjunctions = []

    @subf.map(&:to_cnf).each do |f|
      if f.is_a?(Disjunction)
        terms += f.subf
      elsif f.is_a?(Conjunction)
        conjunctions << f
      else
        terms << f
      end
    end

    clauses = []

    conjunctions.each do |c|
      rest = conjunctions.select{|cl| cl != c}

      clauses += c.subf.map{|cl| Disjunction.new([cl] + terms + rest)}
    end

    if !clauses.empty?
      cnf_clauses = Conjunction.new(clauses).to_cnf().subf

      filtered = []

      cnf_clauses.each do |c|
        if !filtered.any? {|f| f.equals(c) }
          filtered << c
        end
      end

      return Conjunction.new(filtered.sort_by(&:to_s), true)
    else
      return Disjunction.new(terms.sort_by(&:to_s), true)
    end
  end

  def derivation_tree
    if @subf.length < 1
      raise "Too few subformulas in a conjunction"
    elsif @subf.length == 1
      @subf[0].derivation_tree
    else
      Disjunction.new(@subf.map(&:derivation_tree))
    end
  end

  def get_children
    @subf
  end

  def encode_tseitin(new_var, subf)
    return Equivalence.new(new_var, Disjunction.new(subf)).to_cnf
  end

  def equals(f)
    return false if !f.is_a?(Disjunction)

    @subf.zip(f.subf).all? {|c1, c2| c1.equals(c2)}
  end

  def clone
    Disjunction.new(@subf.map(&:clone), @is_cnf)
  end
end

class Negation < Formula
  def initialize(subformula, is_cnf = false)
    super(is_cnf)
    @subf = subformula
  end

  def to_s
    return "!#{@subf.to_s}"
  end

  def to_cnf
    return self if @is_cnf

    if @subf.is_a?(Variable)
      return Negation.new(@subf.to_cnf, true)
    elsif @subf.is_a?(Negation)
      return @subf.subf.to_cnf
    elsif @subf.is_a?(Disjunction)
      return Conjunction.new(@subf.subf.map{|f| Negation.new(f)}).to_cnf
    elsif @subf.is_a?(Conjunction)
      return Disjunction.new(@subf.subf.map{|f| Negation.new(f)}).to_cnf
    else
      return Negation.new(@subf.to_cnf).to_cnf
    end
  end

  def derivation_tree
    Negation.new(@subf.derivation_tree)
  end

  def get_children
    [@subf]
  end

  def encode_tseitin(new_var, subf)
    if subf.length != 1
      raise "Too few sub formulas"
    end

    return Equivalence.new(new_var, Negation.new(subf[0])).to_cnf
  end

  def equals(f)
    return false if !f.is_a?(Negation)

    return @subf.equals(f.subf)
  end

  def clone
    Negation.new(@subf.clone, @is_cnf)
  end
end

class Variable < Formula
  attr_accessor :name
  def initialize(name, is_cnf = false)
    super(is_cnf)
    @name = name
    @subf = []
  end

  def to_s
    @name
  end

  def to_cnf
    return self if @is_cnf

    return Variable.new(@name, true)
  end

  def derivation_tree
    self.clone
  end

  def get_children
    []
  end

  def encode_tseitin(new_var, subf)
    raise "encode_tseitin should not be called on variable"
  end

  def equals(f)
    return false if !f.is_a?(Variable)

    return @name == f.name
  end

  def clone
    return Variable.new(@name, @is_cnf)
  end
end

class Implication < Formula
  def initialize(premise, conclusion, is_cnf = false)
    super(is_cnf)
    @premise = premise
    @conclusion = conclusion
  end

  def to_s
    "#{@premise.to_s} => #{@conclusion.to_s}"
  end

  def to_cnf
    Disjunction.new([Negation.new(@premise), @conclusion]).to_cnf
  end

  def derivation_tree
    Implication.new(@premise.derivation_tree, @conclusion.derivation_tree)
  end

  def get_children
    [@premise, @conclusion]
  end

  def encode_tseitin(new_var, subf)
    raise "Must have two subformlas" if subf.length < 2

    Equivalence.new(new_var, Implication.new(subf[0], subf[1])).to_cnf
  end

  def equals(f)
    return false if !f.is_a?(Implication)

    @premise.equals(f.premise) && @conclusion.equals(f.conclusion)
  end

  def clone
    Implication.new(@premise.clone, @conclusion.clone)
  end
end

class Equivalence < Formula
  def initialize(left, right, is_cnf = false)
    super(is_cnf)
    @left = left
    @right = right
  end

  def to_s
    "#{@left.to_s} <=> #{@right.to_s}"
  end

  def to_cnf
    Conjunction.new([Implication.new(@left, @right), Implication.new(@right, @left)]).to_cnf
  end

  def derivation_tree
    Equivalence.new(@left.derivation_tree, @right.derivation_tree)
  end

  def get_children
    [@left, @right]
  end

  def encode_tseitin(new_var, subf)
    raise "Must have two subformulas" if subf.length != 2

    Equivalence.new(new_var, Equivalence.new(subf[0], subf[1])).to_cnf
  end

  def equals(f)
    return false if !f.is_a?(Equivalence)

    @left.equals(f.left) && @right.equals(f.right)
  end

  def clone
    Equivalence.new(@left.clone, @right.clone())
  end
end