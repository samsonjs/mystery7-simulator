#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'trollop'
require './roulette'

def main
  options = Trollop::options do
    opt :american, "American style, with 00", :short => 'a', :default => true
    opt :database, "Filename for results database", :type => String, :default => File.expand_path("~/Projects/Mystery7/results.sqlite")
    opt :european, "European style, without 00", :short => 'e', :default => false
    opt :misses, "Number of misses before sleeping", :short => 'm', :default => 4
    opt :record, "Record results", :short => 'r'
    opt :seed, "Seed for the RNG", :type => :int
    opt :sessions, "Number of sessions to simulate", :short => 's', :type => :int, :default => 1000
    opt :spins, "Number of spins", :short => 'n', :type => :int, :default => 45
    opt :verbose, "Print stats after each spin", :short => 'v'
  end

  options[:style] = options[:european] ? 'European' : 'American'
  puts ">>> Simulating #{options[:sessions]} #{options[:style]} style sessions of #{options[:spins]} spins, sleeping after #{options[:misses]} miss#{options[:misses] > 0 ? 'es' : ''}..."

  roulette = Roulette.new(options.dup)

  puts ">>> Seed: #{roulette.seed}"

  overall_status = {
    :net => 0,
    :snakes => 0,
    :wins => 0
  }

  # all_results = []

  options[:sessions].times do

    roulette.simulate

    status = {
      :net => 0,
      :snakes => 0,
      :wins => 0
    }

    Roulette::Sets.each do |letter, set|
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

    # all_results += roulette.results

  end

  puts "Net profit: #{overall_status[:net]}"
  puts "Wins: #{overall_status[:wins]}"
  puts "Snakes: #{overall_status[:snakes]}"

  # File.open(File.expand_path('~/Dropbox/Mystery7/results.csv'), 'w') do |f|
  #   f.puts('Roll, Net, Cumulative Net')
  #   all_results.each do |result|
  #     f.puts("#{result[:roll]}, #{result[:net]}, #{result[:cumulative_net]}")
  #   end
  # end

  puts ">>> Results are in #{options[:database]}." if options[:record]
end

main if __FILE__ == $0
