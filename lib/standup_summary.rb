require "standup_summary/version"
require 'optparse'
require 'date'
require 'active_support'
require 'active_support/core_ext/date'
require 'active_support/core_ext/time'

module StandupSummary
  class CLI

    def initialize
      @path = "#{ENV['HOME']}/"
      @time_span = :today
      @date = Date.current
      @args = "-A \"#{@date} 00:00\" -B \"#{@date} 23:59\""
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: standup.rb [options]"

        opts.on('-pPATH', '--path PATH', String, "Where to scan stand-up(relative to your home directory)") do |path|
          @path += path
        end

        opts.on('-t', '--today', "Displays today standup") do
          @args = "-A \"#{@date} 00:00\" -B \"#{@date} 23:59\""
        end

        opts.on('-w', '--week', "Displays standup for this week") do
          @args = "-A \"#{@date.beginning_of_week} 00:00\" -B \"#{@date.beginning_of_week + 4} 23:59\""
        end

        opts.on('-m', '--month', "Displays standup for this month") do
          @args = "-A \"#{@date.beginning_of_month} 00:00\" -B \"#{@date.end_of_month} 23:59\""
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end
      parser.parse!
    end

    def run
      puts "Entering #{@path} ..."

      Dir.chdir(@path) do
        cmd = "git standup -s #{@args}"
        puts "Running #{cmd}"
        puts
        out = `#{cmd}`
        # out.split(/\/home\/.*$/)
        total_count = `#{cmd} | grep -v #{@path}* -c`
        projects = `#{cmd} | grep #{@path}* --color=never`
        projects = projects.split("\n")
        project_hash = {}
        commits_per_project = out.split(/\/home\/.*$/)
        commits_per_project.delete_at(0)
        commits_per_project.each_with_index do |commits, index|
          count = commits.split("\\n\n").count
          project_hash[projects[index]] = {
            count: count,
            percentage: (count / total_count.to_f * 100)
          }
        end
        puts "Total projects: #{projects.size}, total commits: #{total_count}"
        project_hash.each do |project, hash|
          project = +project
          project.slice!("#{@path}/")
          puts "#{project} commits: #{hash[:count]}/#{hash[:percentage].floor(2)}%"
        end
      end
    end
  end
end
