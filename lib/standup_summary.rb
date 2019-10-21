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
      @date = Date.current
      @options = { path: "#{ENV['HOME']}/",
                   recursive: false,
                   limit: 3,
                   mode: :commits,
                   days: nil,
                   from: @date,
                   to: @date }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: standup / standup_summary [options]"

        opts.on('-p PATH', '--path PATH', String, "Where to scan stand-up (relative to your home directory)") do |path|
          @options[:path] += path
        end

        opts.on('-d DAYS', '--days days', Integer, "Specify the number of days back to include, same as 'git standup -d', ignores any other time param") do |days|
          @options[:days] = days
        end

        opts.on('-t', '--today', "Displays today standup") do
          @options[:from] = @date
          @options[:to] = @date
        end

        opts.on('-w', '--week', "Displays standup for this week") do
          @options[:from] = @date.beginning_of_week
          @options[:to] = @date.beginning_of_week + 4
        end

        opts.on('-m', '--month', "Displays standup for this month") do
          @options[:from] = @date.beginning_of_month
          @options[:to] = @date.end_of_month

        end

        opts.on('-f', '--diff', "Analyze diffs instead of commits") do
          @options[:mode] = :diffs
        end

        opts.on('-r', '--recursive', "When using -f go through folders recursively, use -l option to set limit") do
          @options[:recursive] = true
        end

        opts.on('-v', '--version', "Print out version") do
          puts "\nStandupSummary by David Podroužek \nversion: #{StandupSummary::VERSION}"
          exit 0
        end

        opts.on('-l LIMIT', '--limit LIMIT', Integer, "Set limit for options -r -f defaults to 3") do |limit = 3|
          @options[:limit] = limit
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
      if @options[:mode] == :diffs
        DiffAnalyzer.new(@options[:path], @options).run!
        return
      end

      if @options[:days].present?
        @args = "-d #{@options[:days]}"
      else
        @args = "-A \"#{@options[:from]} 00:00\" -B \"#{@options[:to]} 23:59\""
      end
      puts "Entering #{@options[:path]} ..."

      Dir.chdir(@options[:path]) do
        cmd = "git standup -s #{@args}"
        puts "Running #{cmd}"
        puts
        out = `#{cmd}`
        # out.split(/\/home\/.*$/)
        total_count = `#{cmd} | grep -v "#{@options[:path]}/*" -c`
        projects = `#{cmd} | grep "#{@options[:path]}/*" --color=never`
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
          next if project.nil?

          project = +project
          project.slice!("#{@options[:path]}/")
          puts "#{project}: #{hash[:count]} / #{hash[:percentage].floor(2)}%"
        end
      end
    end
  end
end
