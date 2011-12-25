#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'trollop'
require './roulette'

def main
  options = Trollop::options do
    opt :american, "American style, with 00", :short => 'a', :default => true
    opt :database, "Filename for results database", :type => String, :default => File.expand_path("~/Projects/Mystery7/results.sqlite")
    opt :'dump-results', "Dump results to results.csv in Dropbox"
    opt :'dump-wins', "Dump wins to wins.csv in Dropbox"
    opt :european, "European style, without 00", :short => 'e', :default => false
    opt :misses, "Number of misses before sleeping", :short => 'm', :default => 4
    opt :mystery7, "Use Mystery7 sets", :default => true
    opt :mystery16, "Use Mystery16 set"
    opt :record, "Record results", :short => 'r'
    opt :seed, "Seed for the RNG", :type => :int
    opt :sessions, "Number of sessions to simulate", :short => 's', :type => :int, :default => 1000
    opt :sleep, "Sleep after N misses", :default => true
    opt :spins, "Number of spins", :short => 'n', :type => :int, :default => 45
    opt :verbose, "Print stats after each spin", :short => 'v'
  end

  options[:style] = options[:european] ? 'European' : 'American'
  options[:set] = options[:mystery16] ? :mystery16 : :mystery7
  if options[:mystery16]
    options[:mystery7] = false
    options[:sleep] = false
  end
  print ">>> Simulating #{options[:sessions]} #{options[:style]} style sessions of #{options[:spins]} spins"
  print ", sleeping after #{options[:misses]} miss#{options[:misses] > 0 ? 'es' : ''}" if options[:sleep]
  puts "..."

  roulette = Roulette.new(options.dup)

  # puts ">>> Seed: #{roulette.seed}"

  overall_status = {
    :net => 0,
    :snakes => 0,
    :wins => 0
  }

  all_results = []
  all_wins = []

  options[:sessions].times do

    roulette.simulate

    status = {
      :net => 0,
      :snakes => 0,
      :wins => 0
    }

    Roulette::Sets[options[:set]].each do |letter, set|
      puts "# of #{letter.to_s.upcase}s: #{roulette.counts[letter]}" if options[:verbose]
      set_status = roulette.set_status[letter]
      puts "status: #{set_status.inspect}" if options[:verbose]
      status[:net] += set_status[:net]
      status[:snakes] += set_status[:snakes]
      status[:wins] += set_status[:wins]
    end

    overall_status[:net] += status[:net]
    overall_status[:snakes] += status[:snakes]
    overall_status[:wins] += status[:wins]

    if options[:verbose]
      puts "Net profit: #{status[:net]}"
      puts "Wins: #{status[:wins]}"
      puts "Snakes: #{status[:snakes]}"
    end

    all_results += roulette.results if options[:'dump-results']
    all_wins += roulette.wins if options[:'dump-wins']

  end

  puts "Net profit: #{overall_status[:net]}"
  puts "Wins: #{overall_status[:wins]}"
  puts "Snakes: #{overall_status[:snakes]}"

  if options[:'dump-results']
    File.open(File.expand_path('~/Desktop/results.csv'), 'w') do |f|
      f.puts('Roll, Net, Cumulative Net')
      all_results.each do |result|
        f.puts("#{result[:roll]}, #{result[:net]}, #{result[:cumulative_net]}")
      end
    end
  end

  if options[:'dump-wins']
    File.open(File.expand_path('~/Desktop/wins.csv'), 'w') do |f|
      f.puts('Set, Sequence, Ghost Sequence')
      all_wins.each do |win|
        f.puts("#{win[:set]}, #{win[:sequence]}, #{win[:ghost_sequence]}")
      end
    end
  end

  puts ">>> Results are in #{options[:database]}." if options[:record]
end

main if __FILE__ == $0
