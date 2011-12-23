#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'trollop'
require './roulette'

def main
  options = Trollop::options do
    opt :style, "American or European", :short => 's', :type => String, :default => 'American'
    opt :iterations, "Number of iterations", :short => 'i', :type => :int, :default => 120
    opt :database, "Filename for results database", :type => String, :default => File.expand_path("~/Projects/Mystery7/results.sqlite")
    opt :record, "Record results", :short => 'r'
    opt :seed, "Seed for the RNG", :type => :int
    opt :misses, "Number of misses before sleeping", :short => 'm', :default => 4
    opt :verbose, "Print stats after each spin", :short => 'v'
  end

  # options[:fixed_input] = true
  # options[:input] = [13, 3, 22, 10, 33, 22, 3, 37, 24, 5, 33, 22, 6, 25, 2, 34, 32, 1, 23, 28, 17, 19, 34, 33, 27, 7, 8, 0, 24, 8, 10, 6, 0, 23, 2, 10, 20, 30, 2, 21, 15, 3, 30, 19, 36, 6, 1, 24, 8, 2, 30, 36, 28, 26, 10, 36, 13, 0, 23, 24, 23, 25, 8, 3, 20, 11, 34, 30, 11, 35, 33, 32, 21, 23, 17, 9, 12, 18, 25, 17, 30, 31, 30, 27, 12, 15, 10, 17, 36, 29, 32, 15, 11, 25, 10, 23, 13, 22, 8, 7, 32, 4, 26, 14, 26, 0, 10, 18, 6, 26, 18, 23, 4, 2, 26, 27, 20, 29, 21, 37]
  # options[:iterations] = options[:input].length

  article = options[:style] == 'American' ? 'an' : 'a'
  puts ">>> Simulating #{article} #{options[:style]} style game with #{options[:iterations]} iterations, sleeping after #{options[:misses]} miss#{options[:misses] > 0 ? 'es' : ''}..."

  roulette = Roulette.new(options)

  puts ">>> Seed: #{roulette.seed}"

  roulette.simulate

  status = {
    :net => 0,
    :sequence => 0,
    :sleeping => true,
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

  puts "Net profit: #{status[:net]}"
  puts "Wins: #{status[:wins]}"
  puts "Snakes: #{status[:snakes]}"

  puts ">>> Results are in #{options[:database]}." if options[:record]
end

main if __FILE__ == $0
