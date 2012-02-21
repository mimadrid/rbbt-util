#!/usr/bin/env ruby

code_file = ARGV[0]
output = ARGV[1]

require 'rbbt-util'

code = case 
       when (code_file.nil? or code_file == '-')
         STDIN.read
       else
         Open.read(code_file)
       end

begin
  data = eval code
rescue Exception
  puts "#:rbbt_exec Error"
  puts $!.message
  puts $!.backtrace * "\n"
  exit(-1)
end

data = data.to_s(:sort, true) if TSV === data
data = data * "\n" if Array === data

case
when (output.nil? or output == '-')
  puts data
when output == "file"
  if Misc.filename? data
    tmpfile = data
  else
    tmpfile = TmpFile.tmp_file
    Open.write(tmpfile, data)
  end

  puts tmpfile
else
  Open.write(output, data)
end
