require_relative 'spec_helper'
require_relative '../lib/mtg_api'

RSpec.describe MtgAPI do
  subject(:mtg) { described_class.new }

  it 'query #get_cards within the first page' do
    VCR.use_cassette('cards') do
      cards = mtg.get_cards(page: 1).cards
      expect(cards.count).to be(100)
      abundance = cards.find { |card| card['name'] == 'Abundance' }
      expect(abundance).not_to be_nil
      expect(abundance['set']).to eq('10E')
      expect(abundance['rarity']).to eq('Rare')
    end
  end

  it 'query #get_cards to get total page count' do
    VCR.use_cassette('cards') do
      expect(mtg.get_cards(page: 1).total_pages).to be(502)
    end
  end

  it 'query #get_cards within the last page' do
    VCR.use_cassette('cards_last_page') do
      cards = mtg.get_cards(page: 502).cards
      expect(cards.count).to be(3)
      zendikar = cards.find { |card| card['name'] == 'Zendikar Farguide' }
      expect(zendikar).not_to be_nil
      expect(zendikar['set']).to eq('ZEN')
      expect(zendikar['rarity']).to eq('Common')
    end
  end
end
