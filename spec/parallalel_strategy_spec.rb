require_relative '../lib/parallel_strategy'

RSpec.describe ParallelStrategy do
  subject(:parallel) { described_class.new(mtg_api: mtg_api, workers: 5) }

  let(:mtg_api) { double(:mtg_api) }

  let(:response1) { double(cards: [1, 2, 3], total_pages: 3) }
  let(:response2) { double(cards: [4, 5, 6]) }
  let(:response3) { double(cards: [7]) }

  it '#call queries multiple pages and return all' do
    expect(mtg_api).to receive(:get_cards).with(page: 1).and_return(response1)
    expect(mtg_api).to receive(:get_cards).with(page: 2).and_return(response2)
    expect(mtg_api).to receive(:get_cards).with(page: 3).and_return(response3)
    expect(mtg_api).to receive(:close_connections)
    expect(parallel.call).to match_array([1, 2, 3, 4, 5, 6, 7])
  end
end
