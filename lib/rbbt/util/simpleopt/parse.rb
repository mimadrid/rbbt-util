require 'rbbt/util/simpleopt/accessor'
module SOPT
  def self.fix_shortcut(short, long)
    return short unless short and shortcuts.include?(short)

    chars = long.chars.to_a
    current = [chars.shift]
    short = current * ""

    while shortcuts.include? short
      next_letter = chars.shift
      return nil if next_letter.nil?
      current << next_letter
      short = current * ""
    end

    short
  end

  def self.register(short, long, asterisk, description)
    short = fix_shortcut(short, long)
    shortcuts[short] = long if short
    inputs << long
    input_shortcuts[long] = short
    input_descriptions[long] = description
    input_types[long] = asterisk ? :string : :boolean
  end

  def self.parse(opt_str)
    info = {}

    inputs = []
    opt_str.split(/[:\n]+/).each do |entry|
      entry.strip!
      next if entry.empty?
      names, _sep, description = entry.partition /\s+/
      short, long, asterisk = names.match(/\s*(?:-(.+))?(?:--(.+?))([*])?$/).values_at 1,2,3 

      inputs << long
      register short, long, asterisk, description
    end
    inputs
  end
end