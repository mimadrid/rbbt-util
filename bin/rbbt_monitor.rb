#!/usr/bin/env ruby

require 'rbbt-util'
require 'fileutils'
require 'rbbt/util/simpleopt'
require 'rbbt/workflow/step'
require 'rbbt/util/misc'

options = SOPT.get("-l--list:-z--zombies:-e--errors:-c--clean:-n--name:-a--all:-w--wipe:-f--file*:-q--quick")


YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

def info_files
  Dir.glob('**/*.info')
end

def running?(info)
  Misc.pid_exists? info[:pid]
end

def print_job(file, info, severity_color = nil)
  clean_file = file.sub('.info','')
  if $name
    puts clean_file
  else
    info ||= {:status => :missing_info_file}
    str = [clean_file, info[:status].to_s] * " [ STATUS = " + " ]" 
    str += " (#{running?(info)? :running : :dead} #{info[:pid]})" if info.include? :pid
    str += " (children: #{info[:children_pids].collect{|pid| [pid, Misc.pid_exists?(pid) ? "R" : "D"] * ":"} * ", "})" if info.include? :children_pids

    str = "#{severity_color}" <<  str  << "\033[0m" if severity_color
    puts str
  end
end

def list_jobs(options)

  omit_ok = options[:zombies] || options[:errors]

  info_files.each do |file|
    clean_file = file.sub('.info','')
    begin
      next if File.exists? clean_file and $quick
      info = Step::INFO_SERIALIAZER.load(Open.read(file, :mode => 'rb'))
      next if File.exists? clean_file and info[:status] == :done
    rescue Exception
      puts "Error parsing info file: #{ file }"
      info = nil
    end

    color = case
            when (not info)
              Log::SEVERITY_COLOR[3]
            when info[:status] == :error
              Log::SEVERITY_COLOR[3]
            when (info[:pid] and not running? info)
              Log::SEVERITY_COLOR[2]
            end

    case
    when (not info)
      print_job file, info, color
    when (not omit_ok)
      print_job file, info, color
    when options[:zombies]
      print_job file, info, color if info[:pid] and not running? info
    when options[:errors]
      print_job file, info, color if info[:status] == :error
    end

  end
end

def remove_job(file)
  clean_file = file.sub('.info','')
  FileUtils.rm file if File.exists? file
  FileUtils.rm clean_file if File.exists? clean_file
  FileUtils.rm_rf clean_file + '.files' if File.exists? clean_file + '.files'
end

def clean_jobs(options)
  info_files.each do |file|
    clean_file = file.sub('.info','')
    info = nil
    next if File.exists? clean_file
    begin
      info = Step::INFO_SERIALIAZER.load(Open.read(file, :mode => 'rb'))
    rescue Exception
      Log.debug "Error process #{ file }"
      remove_job file if options[:errors]
    end
    case
    when options[:all]
      remove_job file
    when (options[:errors] and (not info or info[:status] == :error))
      remove_job file
    when (options[:zombies] and info[:pid] and not running? info)
      remove_job file
    end

  end
end



$name = options.delete :name
$quick = options.delete :quick
case
when (options[:clean] and not options[:list])
  if options[:file]
    remove_job options[:file]
  else
    clean_jobs options
  end
else
  if options[:file]
    info = Step::INFO_SERIALIAZER.load(Open.read(options[:file], :mode => 'rb'))
    print_job options[:file], info
  else
    list_jobs options
  end
end
