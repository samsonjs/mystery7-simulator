require 'rubygems'
require 'bundler/setup'
require 'sqlite3'

class Roulette

  Sets = {
    :j => [1, 2, 3, 13, 15, 26, 27],
    :k => [4, 5, 6, 16, 17, 28, 30],
    :m => [7, 8, 19, 20, 21, 31, 32],
    :c => [11, 12, 22, 24, 34, 35, 36],
    :n => [9, 10, 14, 18, 23, 25, 29],
    :z => [0, 2, 16, 19, 33, 36]
  }

  # original
  # BettingSequence = [1, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 8, 10, 12, 15]

  # better
  # BettingSequence = [1, 1, 1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 10, 12, 15, 18]

  # best
  BettingSequence = [1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5, 6, 7, 8, 10, 12, 15, 18]

  attr_accessor :results, :counts, :set_status

  def initialize(options)
    @options = options
    @sets = {}
    Sets.keys.each do |key|
      @sets[key] = Sets[key].dup
    end
    if @options[:american]
      @sets[:z] << 37
    else
      @sets[:z].insert(2, 5)
    end

    @rng = @options[:seed] ? Random.new(@options[:seed]) : Random.new

    # generated numbers are from 0 to max
    @max = @options[:american] ? 38 : 37

    total_per_number = 0
    @net_profits = BettingSequence.map do |n|
      total_per_number += n
      36 * n - 7 * total_per_number
    end
    @snake_penalty = 7 * total_per_number

    @cumulative_net = 0
  end

  def simulate
    @set_status = {}
    Sets.keys.each do |key|
      @set_status[key] = {
        :net => 0,
        :sequence => 0,
        :sleeping => true,
        :snakes => 0,
        :wins => 0
      }
    end

    @results = []
    @counts = Hash.new { 0 }

    @options[:spins].times do
      result = spin
      record(result) if @options[:record]
      if @results.length % 100_000 == 0
        print @results.length / 100000
      elsif @results.length % 10_000 == 0
        print '.'
      end
    end
    puts if @results.length >= 10_000
  end

  def spin
    n = @rng.rand(@max)
    letters = []
    net = 0
    @sets.each do |letter, set|
      status = @set_status[letter]
      if set.include?(n)
        if status[:sleeping]
          status[:sleeping] = false
        else
          net = @net_profits[status[:sequence]]
          status[:net] += net
          status[:sequence] = 0
          status[:wins] += 1
        end
        @counts[letter] += 1
        letters << letter
      end
    end
    @set_status.each do |letter, status|
      next if letters.include?(letter)
      status[:sequence] += 1 unless status[:sleeping]
      # snake
      if status[:sequence] >= BettingSequence.length
        puts "#{letter}: SNAKE!" if @options[:verbose]
        status[:sequence] = 0
        status[:sleeping] = true
        status[:snakes] += 1
        status[:net] -= @snake_penalty
        net -= @snake_penalty
      end
      if status[:sequence] > 0 && status[:sequence] % @options[:misses] == 0
        status[:sleeping] = true
      end
    end
    @cumulative_net += net
    result = {
      :roll => n,
      :net => net,
      :cumulative_net => @cumulative_net
    }
    if @options[:verbose]
      puts @results.length
      puts result.inspect
      @set_status.each do |letter, status|
        puts "#{letter}: #{status.inspect}"
      end
      puts
    end
    @results << result
    result
  end

  def seed
    @rng.seed
  end

  def db
    unless @db
      @db = SQLite3::Database.new(@options[:database])
      @db.execute('drop table if exists results')
      @db.execute('create table results (roll integer, sets varchar(10), parity varchar(1), colour varchar(1), highlow varchar(1), abc varchar(1), fmu varchar(1))')
    end
    @db
  end

  def record(result)
    db.execute("insert into results values (#{result.roll}, '#{result.sets}', '#{result.parity}', '#{result.colour}', '#{result.highlow}', '#{result.abc}', '#{result.fmu}')")
  rescue
    sleep 1
    record(result)
  end

end
