require_relative 'utils/progressbar'

class BlockStrategy
  include Progressbar

  def initialize(mtg_api: nil, block_size: 25)
    @block_size = block_size
    @mtg_api = mtg_api || MtgAPI.new(pool_size: block_size)
  end

  def call
    first_page = @mtg_api.get_cards(page: 1)
    all_cards = first_page.cards
    progressbar_start(total: first_page.total_pages)

    (2..first_page.total_pages).each_slice(@block_size) do |pages|
      requests = pages.map do |page|
        Thread.new do
          chunk = @mtg_api.get_cards(page: page).cards
          progressbar_advance
          chunk
        end
      end
      all_cards += requests.map(&:value).flatten
    end

    @mtg_api.close_connections

    all_cards
  end
end
