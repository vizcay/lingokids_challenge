require_relative '../sequential_strategy'

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
  if ARGV.include?('--sequential')
    SequentialStrategy.new
  else
    ParallelStrategy.new
  end
end
