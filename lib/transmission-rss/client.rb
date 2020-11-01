require 'net/http'
require 'json'
require 'base64'

require File.join(File.dirname(__FILE__), 'log')

module TransmissionRSS
  # Class for communication with transmission utilizing the RPC web interface.
  class Client
    OPTIONS = [:paused, :download_dir]

    class Unauthorized < StandardError
    end

    def initialize(server = {}, login = nil, options = {})
      options ||= {}

      @host     = server.host || 'localhost'
      @port     = server.port || 9091
      @tls      = !!server.tls
      @rpc_path = server.rpc_path || '/transmission/rpc'
      @login    = login

      @timeout  = options.timeout || 5
      @log      = TransmissionRSS::Log.instance
    end

    def rpc(method, arguments)
      sid = get_session_id
      raise Unauthorized unless sid

      post = Net::HTTP::Post.new \
        @rpc_path,
        {
          'Content-Type' => 'application/json',
          'X-Transmission-Session-Id' => sid
        }

      add_basic_auth(post)
      post.body = {method: method, arguments: arguments}.to_json

      JSON.parse(request(post).body)
    end

    # POST json packed torrent add command.
    def add_torrent(file, type = :url, options = {})
      arguments = set_arguments_from_options(options)

      case type
        when :url
          file = URI.escape(file) if URI.unescape(file) == file
          arguments.filename = file
        when :file
          arguments.metainfo = Base64.encode64(File.read(file))
        else
          raise ArgumentError.new('type has to be :url or :file.')
      end

      response = rpc('torrent-add', arguments)
      id = get_id_from_response(response)

      log_message = 'torrent-add result: ' + response.result
      log_message << ' (id ' + id.to_s + ')' if id
      @log.debug(log_message)

      if id && options[:seed_ratio_limit]
        if options[:seed_ratio_limit].to_f < 0
          set_torrent(id, {
            'seedRatioMode' => 2
          })
        else
          set_torrent(id, {
            'seedRatioLimit' => options[:seed_ratio_limit].to_f,
            'seedRatioMode' => 1
          })
        end
      end

      response
    end

    def set_torrent(id, arguments = {})
      arguments.ids = [id]
      response = rpc('torrent-set', arguments)
      @log.debug('torrent-set result: ' + response.result)

      response
    end

    # Get transmission session id.
    def get_session_id
      get = Net::HTTP::Get.new(@rpc_path)

      add_basic_auth(get)

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

    def add_basic_auth(request)
      return if @login.nil?
      request.basic_auth(@login['username'], @login['password'])
    end

    def get_id_from_response(response)
      response.arguments.first.last.id
    rescue
    end

    def http_request(data)
      Net::HTTP.start(@host, @port, use_ssl: @tls) do |http|
        http.request(data)
      end
    end

    def request(data)
      c ||= 0

      Timeout.timeout(@timeout) do
        @log.debug("request #@host:#@port")
        http_request(data)
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

    def set_arguments_from_options(options)
      arguments = {}

      OPTIONS.each do |o|
        unless options[o].nil?
          arguments[o.to_s.sub('_', '-')] = options[o]
        end
      end

      arguments
    end
  end
end
