require_relative '../lib/card_repository'

RSpec.describe CardRepository do
  subject(:cards) { described_class.new(strategy: strategy) }

  let(:strategy) { double(:strategy) }

  it 'returns #all cards as readed from injected strategy' do
    card_list = double(:card_list)
    expect(strategy).to receive(:call).and_return(card_list)
    expect(cards.all).to eq(card_list)
  end

  it 'returns cards #by_set' do
    card_list = [
      { 'name' => 'card1', 'set' => 'set1' },
      { 'name' => 'card2', 'set' => 'set2' },
      { 'name' => 'card3', 'set' => 'set1' }
    ]
    expect(strategy).to receive(:call).and_return(card_list)
    by_set = cards.by_set
    expect(by_set.keys).to eq(['set1', 'set2'])
    expect(by_set['set1'].size).to eq(2)
    expect(by_set['set1']).to include({ 'name' => 'card1', 'set' => 'set1' })
    expect(by_set['set2'].size).to eq(1)
  end

  let(:card1) { { 'set' => '2001', 'rarity' => 'common' } }
  let(:card2) { { 'set' => '2001', 'rarity' => 'common' } }
  let(:card3) { { 'set' => '2001', 'rarity' => 'exotic' } }
  let(:card4) { { 'set' => '2002', 'rarity' => 'common' } }

  it 'reeturns cards #by_set_and_rarity' do
    expect(strategy).to receive(:call).and_return([card1, card2, card3, card4])
    by_set_and_rarity = cards.by_set_and_rarity
    expect(by_set_and_rarity['2001']['common']).to include(card1)
    expect(by_set_and_rarity['2001']['common']).to include(card2)
    expect(by_set_and_rarity['2001']['exotic']).to include(card3)
    expect(by_set_and_rarity['2002']['common']).to include(card4)
  end
end
