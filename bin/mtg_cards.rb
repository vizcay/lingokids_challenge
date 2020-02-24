require_relative '../lib/card_repository'
require_relative '../lib/utils/terminal_helpers'

card_repository = CardRepository.new

puts "Cards grouped by set\n"
card_repository.by_set.each_pair do |set, cards|
  puts "\n< SET #{set} >"
  puts card_list(cards)
  continue
end

puts "\nCards grouped by set and then each set grouped by rarity"
card_repository.by_set_and_rarity.each_pair do |set, by_rarity|
  by_rarity.each_pair do |rarity, cards|
    puts "\n< SET #{set} - RARITY #{rarity} >"
    puts card_list(cards)
    continue
  end
end

puts "\nCards from the Khans of Tarkir (KTK) that ONLY have the colours red AND blue"
ktk_red_and_blue = card_repository.
                     by_set['KTK'].
                     select { |card| card['colors'].include?('Red') &&
                                     card['colors'].include?('Blue') }
puts card_list(ktk_red_and_blue)
