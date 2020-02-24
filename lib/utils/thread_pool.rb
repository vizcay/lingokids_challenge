module Utils
  class ThreadPool
    def initialize(size: 8)
      @size = size
      @pending = Queue.new
      @pool = Array.new(size) do
        Thread.new do
          catch(:stop) do
            loop do
              @pending.pop.call
            end
          end
        end
      end
    end

    def schedule(&block)
      @pending << block
    end

    def wait_for_all
      @size.times do
        schedule { throw :stop }
      end
      @pool.map(&:join)
    end
  end
end
