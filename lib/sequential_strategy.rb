require 'tty-progressbar'
require_relative 'mtg_api'

class SequentialStrategy
  def initialize(mtg_api: MtgAPI.new)
    @mtg_api = mtg_api
  end

  BAR = "[:bar] :percent | Elapsed: :elapsed | ETA: :eta"

  def call
    first_page = @mtg_api.get_cards(page: 1)

    progress = TTY::ProgressBar.new(BAR, head: '>', total: first_page.total_pages)
    progress.start

    (2..first_page.total_pages).map do |page|
      @mtg_api.get_cards(page: page).cards.tap do
        progress.advance
      end
    end.flatten + first_page.cards
  end
end
