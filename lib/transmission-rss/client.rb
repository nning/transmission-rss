require 'net/http'
require 'json'
require 'base64'

require File.join(File.dirname(__FILE__), 'log')

module TransmissionRSS
  # Class for communication with transmission utilizing the RPC web interface.
  class Client
    class Unauthorized < StandardError
    end

    def initialize(server = {}, login = nil, options = {})
      @host     = server[:host] || 'localhost'
      @port     = server[:port] || 9091
      @rpc_path = server[:rpc_path] || '/transmission/rpc'
      @login    = login

      @timeout  = options[:timeout] || 5
      @log      = TransmissionRSS::Log.instance
    end

    # POST json packed torrent add command.
    def add_torrent(file, type, options = {})
      hash = {
        'method' => 'torrent-add',
        'arguments' => {
          'paused' => options[:paused],
          'download-dir' => options[:download_path]
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
        @rpc_path,
        {
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
      get = Net::HTTP::Get.new(@rpc_path)

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
      c ||= 0

      Timeout.timeout(@timeout) do
        @log.debug("request #@host:#@port")
        http_get(data)
      end
    rescue Errno::ECONNREFUSED
      @log.debug('connection refused')
      raise
    rescue Timeout::Error
      s  = 'connection timeout'
      s << " (retry #{c})" if c > 0
      @log.debug(s)

      c += 1
      retry unless c > 2

      raise
    end

    def http_get(data)
      Net::HTTP.new(@host, @port).start do |http|
        http.request(data)
      end
    end
  end
end
