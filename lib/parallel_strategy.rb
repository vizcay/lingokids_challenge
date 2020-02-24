require_relative 'mtg_api'
require_relative 'utils/thread_pool'

class ParallelStrategy
  def initialize(mtg_api: nil, workers: 35)
    @workers = workers
    @mtg_api = mtg_api || MtgAPI.new(pool_size: @workers)
  end

  def call
    thread_pool = Utils::ThreadPool.new(size: @workers)
    mutex = Mutex.new

    all_cards = []
    @mtg_api.get_cards_pages.times do |i|
      thread_pool.schedule do
        chunk = @mtg_api.get_cards(page: i.succ)
        mutex.synchronize { all_cards += chunk }
      end
    end

    thread_pool.wait_for_all
    @mtg_api.close_connections

    all_cards
  end
end
