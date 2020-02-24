class BlockStrategy
  def initialize(mtg_api: nil, block_size: 25)
    @block_size = block_size
    @mtg_api = mtg_api || MtgAPI.new(pool_size: block_size)
  end

  BAR = "[:bar] :percent | Elapsed: :elapsed | ETA: :eta"

  def call
    first_page = @mtg_api.get_cards(page: 1)
    all_cards = first_page.cards

    progress = TTY::ProgressBar.new(BAR, head: '>', total: first_page.total_pages)
    progress.start

    (2..first_page.total_pages).each_slice(@block_size) do |pages|
      requests = pages.map do |page|
        Thread.new do
          @mtg_api.get_cards(page: page).cards.tap do
            progress.advance
          end
        end
      end
      all_cards += requests.map(&:value).flatten
    end

    @mtg_api.close_connections

    all_cards
  end
end
