require 'io/console'

def continue
  if ARGV.include?('--interactive')
    puts "\nPress any key to continue..\n"
    STDIN.getch
  end
end

def card_list(cards)
  cards.map { |card| card['name'] }.join(', ')
end
