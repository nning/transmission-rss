require 'net/http'
require 'json'
require 'base64'

# Class for communication with transmission utilizing the RPC web interface.
class TransmissionRSS::Client
  def initialize(host = 'localhost', port = 9091, timeout: 5)
    @host, @port, @timeout = host, port, timeout
    @log = Log.instance
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
        raise ArgumentError.new 'type has to be :url or :file.'
    end

    post = Net::HTTP::Post.new \
      '/transmission/rpc',
      initheader = {
        'Content-Type' => 'application/json',
        'X-Transmission-Session-Id' => get_session_id
      }

    post.body = hash.to_json

    response = request post

    result = JSON.parse(response.body).result

    @log.debug 'add_torrent result: ' + result
  end

  # Get transmission session id.
  def get_session_id
    get = Net::HTTP::Get.new '/transmission/rpc'
    response = request get

    id = response.header['x-transmission-session-id']

    @log.debug 'got session id ' + id

    id
  end

  private

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
