require 'net/http'
require 'json'
require_relative 'utils/connection_pool'

class MtgAPI
  def initialize(pool_size: 1)
    @connection_pool = Utils::ConnectionPool.new(size: pool_size) do
      Net::HTTP.start('api.magicthegathering.io', 443, use_ssl: true)
    end
  end

  def get_cards(page:)
    @connection_pool.with do |connection|
      response = connection.request_get("/v1/cards?page=#{page}")
      JSON.parse(response.body)['cards']
    end
  end

  def get_cards_pages
    @connection_pool.with do |connection|
      headers = connection.request_head('/v1/cards')
      return (headers['Total-count'].to_f / headers['Page-size'].to_f).ceil
    end
  end

  def close_connections
    @connection_pool.shutdown { |connection| connection.finish }
  end
end
