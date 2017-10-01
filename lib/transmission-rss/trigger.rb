require 'socket'
libdir = File.dirname(__FILE__)
require File.join(libdir, 'log')

class String
  def truncate(max)
    length > max ? "#{self[0...max]}..." : self
  end
end

module TransmissionRSS
  class Trigger
    def initialize(aggregator, port = 5678)
      @aggregator = aggregator
      @stop = false
      @server = TCPServer.new port
      @log = Log.instance
      @app = proc do |x|
        if x['PATH_INFO'].chomp('/') != '/scan' || x['REQUEST_METHOD'] != 'POST'
          ['404', { 'Content-Type' => 'text/html' }, ['Not found.']]
        else
          @aggregator.scan_now
          ['200', { 'Content-Type' => 'text/html' }, ['Starting scan...']]
        end
      end
      start
      @log.info('trigger-server started (' + port.to_s + ')')
    end

    def start
      Thread.new do
        loop do
          Thread.start(@server.accept) do |client|
            handle_client(client)
          end
        end
      end
    end

    def handle_client(client)
      got = client.gets
      if got.nil?
        @log.error 'trigger_server got nil request'
        return
      end
      got = got.chomp
      @log.info "trigger_server got: #{got.truncate(50)}"
      # 1
      method, full_path = got.split(' ')
      # 2
      path, query = full_path.split('?')
      # 3
      status, headers, body = @app.call('REQUEST_METHOD' => method,
                                        'PATH_INFO' => path,
                                        'QUERY_STRING' => query)

      client.print "HTTP/1.1 #{status}\r\n"
      headers.each do |key, value|
        client.print "#{key}: #{value}\r\n"
      end
      client.print "\r\n"
      body.each do |part|
        client.print part
      end
    rescue => e
      @log.error e.to_s
    ensure
      client.close
    end

    def stop
      @server.close
    end
  end
end
