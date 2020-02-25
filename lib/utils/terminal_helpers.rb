require 'io/console'
require_relative '../sequential_strategy'
require_relative '../block_strategy'

GC.disable if ARGV.include?('--disable-gc')

def continue
  if ARGV.include?('--interactive')
    puts "\nPress any key to continue..\n"
    STDIN.getch
  end
end

def card_list(cards)
  cards.map { |card| card['name'] }.join(', ')
end

def strategy_factory
  if ARGV.include?('--sequential-requests')
    SequentialStrategy.new
  elsif ARGV.include?('--block-requests')
    BlockStrategy.new
  else
    match = ARGV.map { |arg| arg.match(/--workers=(\d+)/)&.[](1) }.compact
    workers = match.first.to_i unless match.empty?
    ParallelStrategy.new(workers: workers || 30)
  end
end
