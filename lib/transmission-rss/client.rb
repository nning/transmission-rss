require 'net/http'
require 'json'
require 'base64'

require File.join(File.dirname(__FILE__), 'log')

module TransmissionRSS
  # Class for communication with transmission utilizing the RPC web interface.
  class Client
    class Unauthorized < StandardError
    end

    def initialize(host = 'localhost', port = 9091, login = nil, timeout: 5)
      @host, @port, @login, @timeout = host, port, login, timeout
      @log = TransmissionRSS::Log.instance
    end

    # POST json packed torrent add command.
    def add_torrent(file, type, paused = false)
      hash = {
        'method' => 'torrent-add',
        'arguments' => {
          'paused' => paused
        }
      }

      case type
        when :url
          hash.arguments.filename = file
        when :file
          hash.arguments.metainfo = Base64.encode64(File.read(file))
        else
          raise ArgumentError.new('type has to be :url or :file.')
      end

      sid = get_session_id
      raise Unauthorized unless sid

      post = Net::HTTP::Post.new \
        '/transmission/rpc',
        initheader = {
          'Content-Type' => 'application/json',
          'X-Transmission-Session-Id' => sid
        }

      auth(post)

      post.body = hash.to_json

      response = request(post)

      result = JSON.parse(response.body).result

      @log.debug('add_torrent result: ' + result)
    end

    # Get transmission session id.
    def get_session_id
      get = Net::HTTP::Get.new('/transmission/rpc')

      auth(get)

      response = request(get)

      id = response.header['x-transmission-session-id']

      if id.nil?
        @log.debug("could not obtain session id (#{response.code}, " +
          "#{response.class})")
      else
        @log.debug('got session id ' + id)
      end

      id
    end

    private

    def auth(request)
      unless @login.nil?
        request.basic_auth(@login['username'], @login['password'])
      end
    end

    def request(data)
      Timeout::timeout(@timeout) do
        Net::HTTP.new(@host, @port).start do |http|
          http.request data
        end
      end
    rescue Errno::ECONNREFUSED
      @log.debug 'connection refused'
      raise
    rescue Timeout::Error
      @log.debug 'connection timeout'
      raise
    end
  end
end
