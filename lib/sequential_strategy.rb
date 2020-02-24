require 'tty-progressbar'
require_relative 'mtg_api'
require_relative 'utils/progressbar.rb'

class SequentialStrategy
  include Progressbar

  def initialize(mtg_api: MtgAPI.new)
    @mtg_api = mtg_api
  end

  def call
    first_page = @mtg_api.get_cards(page: 1)
    progressbar_start(total: first_page.total_pages)
    (2..first_page.total_pages).map do |page|
      chunk = @mtg_api.get_cards(page: page).cards
      progressbar_advance
      chunk
    end.flatten + first_page.cards
  end
end
