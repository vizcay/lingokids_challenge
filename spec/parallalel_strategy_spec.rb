require_relative '../lib/parallel_strategy'

RSpec.describe ParallelStrategy do
  subject(:parallel) { described_class.new(mtg_api: mtg_api, workers: 5) }

  let(:mtg_api) { double(:mtg_api) }

  it '#call queries multiple pages and return all' do
    expect(mtg_api).to receive(:get_cards_pages).and_return(3)
    expect(mtg_api).to receive(:get_cards).with(page: 1).and_return([1, 2, 3])
    expect(mtg_api).to receive(:get_cards).with(page: 2).and_return([4, 5, 6])
    expect(mtg_api).to receive(:get_cards).with(page: 3).and_return([7])
    expect(mtg_api).to receive(:close_connections)
    expect(parallel.call).to match_array([1, 2, 3, 4, 5, 6, 7])
  end
end
