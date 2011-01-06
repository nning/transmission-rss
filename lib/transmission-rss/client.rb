require 'net/http'
require 'json'
require 'timeout'

# TODO
#  * Why the hell do timeouts in getSessionID and addTorrent not work?!

# Class for communication with transmission utilizing the RPC web interface.
class TransmissionRSS::Client
  def initialize(host, port)
    @host = host
    @port = port

    @log = Log.instance
  end

  # Get transmission session id by simple GET.
  def getSessionID
    get = Net::HTTP::Get.new(
      '/transmission/rpc'
    )

#   retries = 3
#   begin
#     Timeout::timeout(5) do
        response = Net::HTTP.new(@host, @port).start do |http|
          http.request(get)
        end
#     end
#   rescue Timeout::Error
#     puts('timeout error exception') if($verbose)
#     if(retries > 0)
#       retries -= 1
#       puts('getSessionID timeout. retry..') if($verbose)
#       retry
#     else
#       $stderr << "timeout http://#{@host}:#{@port}/transmission/rpc"
#     end
#   end

    id = response.header['x-transmission-session-id']

    @log.debug('got session id ' + id)

    id
  end

  # POST json packed torrent add command.
  def addTorrent(torrentFile, paused = false)
    post = Net::HTTP::Post.new(
      '/transmission/rpc',
      initheader = {
        'Content-Type' => 'application/json',
        'X-Transmission-Session-Id' => getSessionID
      }
    )

    post.body = {
      "method" => "torrent-add",
      "arguments" => {
        "paused" => paused,
        "filename" => torrentFile
      }
    }.to_json

#   retries = 3
#   begin
#     Timeout::timeout(5) do
        response = Net::HTTP.new(@host, @port).start do |http|
          http.request(post)
        end
#     end
#   rescue Timeout::Error
#     puts('timeout error exception') if($verbose)
#     if(retries > 0)
#       retries -= 1
#       puts('addTorrent timeout. retry..') if($verbose)
#       retry
#     else
#       $stderr << "timeout http://#{@host}:#{@port}/transmission/rpc"
#     end
#   end

    result = JSON.parse(response.body).result

    @log.debug('addTorrent result: ' + result)
  end
end
