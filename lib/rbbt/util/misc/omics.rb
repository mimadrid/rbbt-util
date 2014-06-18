module Misc

  IUPAC2BASE = {
    "A" => ["A"],
    "C" => ["C"],
    "G" => ["G"],
    "T" => ["T"],
    "U" => ["U"],
    "R" => "A or G".split(" or "),
    "Y" => "C or T".split(" or "),
    "S" => "G or C".split(" or "),
    "W" => "A or T".split(" or "),
    "K" => "G or T".split(" or "),
    "M" => "A or C".split(" or "),
    "B" => "C or G or T".split(" or "),
    "D" => "A or G or T".split(" or "),
    "H" => "A or C or T".split(" or "),
    "V" => "A or C or G".split(" or "),
    "N" => %w(A C T G),
  }

  BASE2COMPLEMENT = {
    "A" => "T",
    "C" => "G",
    "G" => "C",
    "T" => "A",
    "U" => "A",
  }

  THREE_TO_ONE_AA_CODE = {
    "ala" =>   "A",
    "arg" =>   "R",
    "asn" =>   "N",
    "asp" =>   "D",
    "cys" =>   "C",
    "glu" =>   "E",
    "gln" =>   "Q",
    "gly" =>   "G",
    "his" =>   "H",
    "ile" =>   "I",
    "leu" =>   "L",
    "lys" =>   "K",
    "met" =>   "M",
    "phe" =>   "F",
    "pro" =>   "P",
    "ser" =>   "S",
    "thr" =>   "T",
    "trp" =>   "W",
    "tyr" =>   "Y",
    "val" =>   "V"
  }
  CODON_TABLE = {
    "ATT" => "I",
    "ATC" => "I",
    "ATA" => "I",
    "CTT" => "L",
    "CTC" => "L",
    "CTA" => "L",
    "CTG" => "L",
    "TTA" => "L",
    "TTG" => "L",
    "GTT" => "V",
    "GTC" => "V",
    "GTA" => "V",
    "GTG" => "V",
    "TTT" => "F",
    "TTC" => "F",
    "ATG" => "M",
    "TGT" => "C",
    "TGC" => "C",
    "GCT" => "A",
    "GCC" => "A",
    "GCA" => "A",
    "GCG" => "A",
    "GGT" => "G",
    "GGC" => "G",
    "GGA" => "G",
    "GGG" => "G",
    "CCT" => "P",
    "CCC" => "P",
    "CCA" => "P",
    "CCG" => "P",
    "ACT" => "T",
    "ACC" => "T",
    "ACA" => "T",
    "ACG" => "T",
    "TCT" => "S",
    "TCC" => "S",
    "TCA" => "S",
    "TCG" => "S",
    "AGT" => "S",
    "AGC" => "S",
    "TAT" => "Y",
    "TAC" => "Y",
    "TGG" => "W",
    "CAA" => "Q",
    "CAG" => "Q",
    "AAT" => "N",
    "AAC" => "N",
    "CAT" => "H",
    "CAC" => "H",
    "GAA" => "E",
    "GAG" => "E",
    "GAT" => "D",
    "GAC" => "D",
    "AAA" => "K",
    "AAG" => "K",
    "CGT" => "R",
    "CGC" => "R",
    "CGA" => "R",
    "CGG" => "R",
    "AGA" => "R",
    "AGG" => "R",
    "TAA" => "*",
    "TAG" => "*",
    "TGA" => "*",
  }

  def self.correct_icgc_mutation(pos, ref, mut_str)
    mut = mut_str
    mut = '-' * (mut_str.length - 1) if mut =~/^-[ACGT]/
      mut = "+" << mut if ref == '-'
    [pos, [mut]]
  end

  def self.correct_vcf_mutation(pos, ref, mut_str)
    muts = mut_str.nil? ? [] : mut_str.split(',')
    muts.collect!{|m| m == '<DEL>' ? '-' : m }

    while ref.length >= 1 and muts.reject{|m| m[0] == ref[0]}.empty?
      ref = ref[1..-1]
      raise "REF nil" if ref.nil?
      pos = pos + 1
      muts = muts.collect{|m| m[1..-1]}
    end

    muts = muts.collect do |m|
      case
      when ref.empty?
        "+" << m
      when (m.length < ref.length and (m.empty? or ref.index(m)))
        "-" * (ref.length - m.length)
      when (ref.length == 1 and m.length == 1)
        m
      else
        Log.debug{"Cannot understand: #{[ref, m]} (#{ muts })"}
        '-' * ref.length + m
      end
    end

    [pos, muts]
  end

  def self.IUPAC_to_base(iupac)
    IUPAC2BASE[iupac]
  end


  def self.sort_mutations(mutations)
    mutations.collect do |mutation|
      chr,pos,mut = mutation.split ":"
      chr.sub!(/^chr/i,'')
      chr = 22 if chr == "Y"
      chr = 23 if chr == "X"
      chr = 24 if chr == "MT" or chr == "M"
      [chr.to_i, pos.to_i, mut, mutation]
    end.sort do |a,b|
      case a[0] <=> b[0]
      when -1
        -1
      when 1
        1
      when 0
        case a[1] <=> b[1]
        when -1
          -1
        when 1
          1
        when 0
          a[2] <=> b[2]
        end
      end
    end.collect{|p| p.last }
  end

  def self.ensembl_server(organism)
    date = organism.split("/")[1]
    if date.nil?
      "www.ensembl.org"
    else
      "#{ date }.archive.ensembl.org"
    end
  end

end
