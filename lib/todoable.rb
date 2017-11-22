require "todoable/version"
require 'net/http'

module Todoable
  AUTH_PATH = "/api/authenticate"

  class Todoable
    def initialize(user, password)
      @user = user
      @password = password
      @token = nil
    end

    def api_base_uri
      "http://todoable.teachable.tech"
    end

    def api_uri(path)
      URI.join(api_base_uri, path)
    end

    def authenticate!
      uri = api_uri(AUTH_PATH)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.basic_auth(@user, @password)
      request.initialize_http_header({})
      request['Accept'] = request['Content-Type'] = 'application/json'
      http.request(request)
    end
  end
end
