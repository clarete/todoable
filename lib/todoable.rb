require "todoable/version"
require "net/http"
require "json"

module Todoable
  AUTH_PATH = "/api/authenticate"
  LISTS_PATH = "/api/lists"
  LIST_PATH = "/api/lists/:list_id"
  ITEMS_PATH = "/api/lists/:list_id/items"
  ITEM_PATH = "/api/lists/:list_id/items/:item_id"
  ITEM_FINISHED_PATH = "/api/lists/:list_id/items/:item_id/finish"

  class List
    attr_accessor :name
    attr_accessor :id

    def initialize(todoable, params)
      @todoable = todoable
      @name = params['name']
      @id = params['id']
    end

    def update(name)
      body = {"list": {"name": name}}.to_json
      @todoable.request!("patch", LIST_PATH, { :list_id => @id }, body)
    end

    def delete
      @todoable.request!("delete", LIST_PATH, { :list_id => @id })
    end

    def items
      output = @todoable.request!("get", LIST_PATH, { :list_id => @id })
      output["list"]['items'].collect { |json_item|
        Item.new(@todoable, self, json_item)
      }
    end

    def new_item(name)
      body = {"item": {"name": name}}.to_json
      @todoable.request!("post", ITEMS_PATH, {:list_id => @id}, body)
    end
  end

  class Item
    attr_accessor :name
    attr_accessor :id

    def initialize(todoable, list, params)
      @todoable = todoable
      @list = list
      @name = params['name']
      @id = params['id']
    end

    def mark_finished
      params = {:list_id => @list.id, :item_id => @id}
      @todoable.request!("put", ITEM_FINISHED_PATH, params)
    end

    def delete
      params = {:list_id => @list.id, :item_id => @id}
      @todoable.request!("delete", ITEM_PATH, params)
    end
  end

  class NotAuthenticated < Exception
  end

  class AuthError < Exception
  end

  class Todoable

    attr_accessor :api_base_uri

    def initialize api_uri = nil
      @token = nil
      @api_base_uri = api_uri || "http://todoable.teachable.tech"
    end

    def authenticate user, password
      uri = api_uri(AUTH_PATH)
      request = Net::HTTP::Post.new(uri.request_uri)

      # Prepare headers for authentication & JSON
      request.initialize_http_header({})
      request.basic_auth(user, password)
      request['Accept'] = request['Content-Type'] = 'application/json'

      # Collect response
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(request)
      raise AuthError if response.code.to_i == 401

      # Retrieve token from body
      @token = JSON.parse(response.body)["token"]
    end

    def lists
      request!("get", LISTS_PATH)["lists"].collect { |json_list|
        List.new(self, json_list)
      }
    end

    def new_list(name)
      request!("post", LISTS_PATH, nil, {"list": {"name": name}}.to_json)
    end

    def api_uri(path, params = nil)
      p = path
      params.each {|k, v| p = p.gsub(/(:#{k.to_s})/, v.to_s)} if params
      URI.join(api_base_uri, p)
    end

    def request!(method, uri, params = nil, body = nil)
      raise NotAuthenticated unless @token != nil

      uri = api_uri(uri, params)
      # Choose method
      request = {
        "get" => Net::HTTP::Get,
        "patch" => Net::HTTP::Patch,
        "post" => Net::HTTP::Post,
        "put" => Net::HTTP::Put,
        "delete" => Net::HTTP::Delete,
      }[method].new(uri.request_uri)

      # Configure request object
      request.body = body
      request.initialize_http_header({
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Authorization' => "Token token=\"#{@token}\""
      })

      # Perform request and collect response
      http = Net::HTTP.new(uri.host, uri.port)
      body = http.request(request).body
      JSON.parse(body) if body != nil && !body.empty?
    end
  end
end
