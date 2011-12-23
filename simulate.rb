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
