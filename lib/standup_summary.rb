require "standup-summary/version"
require "standup-summary/diff_analyzer"
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
      @days = nil
      @mode = :commits
      @diff_options = { recursive: false, limit: 3 }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: standup / standup_summary [options]"

        opts.on('-p PATH', '--path PATH', String, "Where to scan stand-up (relative to your home directory)") do |path|
          @path += path
        end

        opts.on('-d DAYS', '--days days', Integer, "Specify the number of days back to include, same as 'git standup -d', ignores any other time param") do |days|
          @days = days
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

        opts.on('-f', '--diff', "Analyze diffs instead of commits") do
          @mode = :diffs
        end

        opts.on('-r', '--recursive', "When using -f go through folders recursively, use -l option to set limit") do
          @diff_options[:recursive] = true
        end

        opts.on('-v', '--version', "Print out version") do
          puts "\nStandupSummary by David Podroužek \nversion: #{StandupSummary::VERSION}"
          exit 0
        end

        opts.on('-l LIMIT', '--limit LIMIT', Integer, "Set limit for options -r -f defaults to 3") do |limit = 3|
          @diff_options[:limit] = limit
        end

        opts.on('-h', '--help', 'Displays Help') do
          puts opts
          exit
        end
      end
      parser.parse!
    end

    # TODO:
    # Use this example:
    #   $ git diff HEAD 'HEAD@{3 weeks ago}' --shortstat -b -w
    # to go through each directory and analyze output "202 files changed, 401 insertions(+), 2959 deletions(-)"
    # Preferably use threads to increase performance
    # add option for shallow loop or deep with limit, default could be 10
    def run
      if @mode == :diffs
        DiffAnalyzer.new(@path, @diff_options).run!
        return
      end
      @args = "-d #{@days}" if @days.present?
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
          puts "#{project}: #{hash[:count]} / #{hash[:percentage].floor(2)}%"
        end
      end
    end
  end
end
