require 'byebug'
require 'find'
module StandupSummary
  class DiffAnalyzer
    STATS = %i[changed insertions deletions]
    TEST = /\s?((?<changed>\d+) files changed)?,?\s((?<insertions>\d+) insertions\(\+\))?,?\s?((?<deletions>\d+) deletions\(\-\))?/

    def initialize(path, options)
      @path = path
      @limit = options[:limit]
      @use_recursive = options[:recursive]
      @options = options
      @results = { directories: [], changed: 0, insertions: 0, deletions: 0, length: 0 }
      @author_name = `git config user.name`.gsub("\n", '')
    end

    def run!
      if @use_recursive
        run_recursive
      else
        run_shallow
      end
      print_results
    end

    def run_recursive
      Find.find(@path) do |path|
        Find.prune if level(path) >= @limit
        Find.prune and next if File.basename(path)[0] == ?.
        next unless File.directory? path
        next unless File.directory? path + '/.git'
        analyze_dir(path)
      end
    end

    def run_shallow
      Dir.foreach(@path) do |path|
        next if File.basename(path)[0] == ?.
        path = @path + '/' + path
        next unless File.directory?(path)
        next unless File.directory? path + '/.git'
        analyze_dir(path)
      end
    end

    def cmd
      @cmd ||= if @options[:days].present?
                 "git log --shortstat --format= --committer=\"#{@author_name}\" --since=\"#{@options[:days]} days ago\""
               else
                 "git log --shortstat --format= --committer=\"#{@author_name}\" --after=\"#{@options[:from]} 00:00\" --before=\"#{@options[:to]} 23:59\""
               end
    end

    def analyze_dir(path)
      project = path.gsub(@path, '')
      project = project[1..-1] if project[0] == '/'
      result = { path: project }
      STATS.each { |s| result[s] = 0 }
      Dir.chdir(path) do
        out = `#{cmd}`
        return if out.blank?
        out.split("\n").each do |line|
          regex = TEST.match line
          STATS.each do |stat|
            val = regex[stat].nil? ? 0 : regex[stat].to_i
            result[stat] += val
            @results[stat] += val
          end
        end
      end
      @results[:length] = project.length if @results[:length] < project.length
      @results[:directories] << result
    end

    def level(sub_dir)
      path = sub_dir.gsub @path, ''
      path = path[1..-1] if path[0] == '/'
      path.split('/').count
    end

    def print_header
      puts "Standup Summary in #{@path}"
      puts
      header = 'Projects'.center(@results[:length] + 1) + ' '
      STATS.each do |s|
        length = @results[s].to_s.length + 10
        header += "|#{s.to_s.capitalize.center(length)}"
      end
      del = ''
      header.length.times { del += '-' }
      puts '+' + del + '+'
      puts '|' + header + '|'
      puts '|' + del + '|'
      '+' + del + '+'
    end

    def print_results
      footer = print_header
      format = "| %-#{@results[:length]}s "
      STATS.each { |s| format += "|%#{@results[s].to_s.length + 1}d / %-6s" }
      format += '|'
      @results[:directories].each do |result|
        args = [result[:path]]
        STATS.each do |s|
          args << result[s]
          args << "#{(result[s] / @results[s].to_f * 100).round(1)}%"
        end

        puts sprintf(format, *args)
      end
      puts footer
    end
  end
end
