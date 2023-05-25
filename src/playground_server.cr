require "http/server"

module Cosmo::PlaygroundServer
  extend self

  def start(&on_start : ->) : Nil
    server = HTTP::Server.new do |context|
      context.response.content_type = "text/plain"
      context.response.print "WIP"
    end

    on_start.call
    server.listen(6060)
  end
end
