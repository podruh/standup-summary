require 'byebug'
require 'find'
module StandupSummary
  class DiffAnalyzer
    STATS = %i[changed insertions deletions]

    def initialize(path, options)
      @path = path
      @limit = options[:limit]
      @use_recursive = options[:recursive]
      @results = {directories: [], changed: 0, insertions: 0, deletions: 0, length: 0}
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

    def analyze_dir(path)
      project = path.gsub(@path, '')[1..-1]
      result = {path: project}
      STATS.each {|s| result[s] = 0}
      test = /\s?((?<changed>\d+) files changed)?,?\s((?<insertions>\d+) insertions\(\+\))?,?\s?((?<deletions>\d+) deletions\(\-\))?/
      Dir.chdir(path) do
        out = `git diff HEAD 'HEAD@{3 weeks ago}' --shortstat -b -w 2> /dev/null`
        return if out.blank?
        regex = test.match out
        STATS.each do |stat|
          val = regex[stat].nil? ? 0 : regex[stat].to_i
          result[stat] = val
          @results[stat] += val
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

    def print_results
      format = "%-#{@results[:length]}s"
      STATS.each {|s|  format += " | #{s.to_s[0].upcase}: %d / %.2f %"}
      @results[:directories].each do |result|
        args = [result[:path]]
        STATS.each do |s|
          args << result[s]
          args << (result[s] / @results[s].to_f * 100)
        end

        puts sprintf(format, *args)
      end
    end
  end
end
