require 'tty-progressbar'
require_relative 'mtg_api'

class SequentialStrategy
  def initialize(mtg_api: MtgAPI.new)
    @mtg_api = mtg_api
  end

  BAR = "[:bar] :percent | Elapsed: :elapsed | ETA: :eta"

  def call
    progress = TTY::ProgressBar.new(BAR, head: '>', total: @mtg_api.get_cards_pages)
    progress.start
    (1..@mtg_api.get_cards_pages).map do |page|
      progress.advance
      @mtg_api.get_cards(page: page)
    end.flatten
  end
end
