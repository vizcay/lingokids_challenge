module Utils
  class ConnectionPool
    def initialize(size: 5, &block)
      @pool        = Queue.new
      @created     = 0
      @size        = size
      @initializer = block
    end

    def pop
      if @pool.empty? && @created < @size
        @pool.push(@initializer.call)
        @created += 1
      end
      @pool.pop
    end

    def push(connection)
      @pool.push(connection)
    end

    def with(&block)
      connection = pop
      block.call(connection)
    ensure
      push(connection)
    end

    def shutdown(&block)
      while !@pool.empty?
        block.call(@pool.pop) rescue nil
      end
    end
  end
end
