require_relative 'parallel_strategy'

class CardRepository
  def initialize(strategy: ParallelStrategy.new)
    @strategy = strategy
  end

  def all
    @all ||= @strategy.call
  end

  def by_set
    @by_set ||= all.group_by { |card| card['set'] }
  end

  def by_set_and_rarity
    @by_set_and_rarity ||= by_set.map do |set, cards|
      [set, cards.group_by { |card| card['rarity'] }]
    end.to_h
  end
end
