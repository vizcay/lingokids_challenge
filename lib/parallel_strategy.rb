require 'tty-progressbar'
require_relative 'mtg_api'
require_relative 'utils/thread_pool'

class ParallelStrategy
  def initialize(mtg_api: nil, workers: 35)
    @workers = workers
    @mtg_api = mtg_api || MtgAPI.new(pool_size: @workers)
  end

  BAR = "[:bar] :percent | Elapsed: :elapsed | ETA: :eta"

  def call
    thread_pool = Utils::ThreadPool.new(size: @workers)
    mutex = Mutex.new

    first_page = @mtg_api.get_cards(page: 1)
    all_cards = first_page.cards

    progress = TTY::ProgressBar.new(BAR, head: '>', total: first_page.total_pages)
    progress.start

    (2..first_page.total_pages).each do |page|
      thread_pool.schedule do
        chunk = @mtg_api.get_cards(page: page).cards
        mutex.synchronize do
          all_cards += chunk
          progress.advance
        end
      end
    end

    thread_pool.wait_for_all
    @mtg_api.close_connections

    all_cards
  end
end
