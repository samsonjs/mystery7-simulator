require 'rubygems'
require 'bundler/setup'
require 'sqlite3'
require './result'

class Roulette

  # B: Black
  # G: Green
  # R: Red
  Colours = {
    'American' => %w[G R B R B R B R B R B B R B R B R B R R B R B R B R B R B B R B R B R B R G],
    'European' => %w[G R B R B R B R B R B B R B R B R B R R B R B R B R B R B B R B R B R B R]
  }

  # F: Foundation
  # M: Middle
  # U: Upper
  FMU = {
    'American' => ['Z'] + %w[F M U] * 12,
    'European' => ['Z'] + %w[F M U] * 12 + ['Z']
  }

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
    @colours = Colours[@options[:style]]
    @fmu = FMU[@options[:style]]
    @sets = {}
    Sets.keys.each do |key|
      @sets[key] = Sets[key].dup
    end
    if @options[:american]
      @sets[:z] << 37
    else
      @sets[:z].insert(2, 5)
    end

    # generated numbers are from 0 to max
    @max = @options[:american] ? 38 : 37

    total_per_number = 0
    @net_profits = BettingSequence.map do |n|
      total_per_number += n
      36 * n - 7 * total_per_number
    end
    @snake_penalty = 7 * total_per_number
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
    @rng = @options[:seed] ? Random.new(@options[:seed]) : Random.new

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
    if @options[:fixed_input]
      n = @options[:input].shift
    else
      n = @rng.rand(@max)
    end
    letters = []
    @sets.each do |letter, set|
      status = @set_status[letter]
      if set.include?(n)
        if status[:sleeping]
          status[:sleeping] = false
        else
          status[:net] += @net_profits[status[:sequence]]
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
      end
      if status[:sequence] > 0 && status[:sequence] % @options[:misses] == 0
        status[:sleeping] = true
      end
    end
    result = Result.new(
      :roll => n,
      :sets => letters.join(','),
      :parity => parity(n),
      :colour => colour(n),
      :highlow => high_or_low(n),
      :abc => abc(n),
      :fmu => fmu(n)
    )
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

  def parity(n)
    if n.even? then 'E' else 'O' end
  end

  def colour(n)
    @colours[n]
  end

  def high_or_low(n)
    if n <= 18 then 'H' else 'L' end
  end

  def abc(n)
    if n <= 12
      'A'
    elsif n <= 24
      'B'
    else
      'C'
    end
  end

  def fmu(n)
    @fmu[n]
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
