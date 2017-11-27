# Copyright (C) 2017  Lincoln Clarete <lincoln@clarete.li>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License (LGPL) as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

  # Class that represents TODO Lists
  class List
    attr_accessor :name
    attr_accessor :id

    # Create new instances of TODO Lists.
    #
    # @param [Todoable::Todoable] todoable Instance of the `Todoable`
    #  class that knows how to perform authenticated requests.
    #
    # @param [Hash] params The parameters of the list. The hash must
    #  contain the fields `name` and `id`.
    def initialize todoable, params
      @todoable = todoable
      @name = params['name']
      @id = params['id']
    end

    # Updates the name of a list
    #
    # @param [String] name The new name for the list
    def update name
      body = {"list": {"name": name}}.to_json
      @todoable.request!("patch", LIST_PATH, { :list_id => @id }, body)
      @name = name
    end

    # Deletes the list
    def delete
      @todoable.request!("delete", LIST_PATH, { :list_id => @id })
    end

    # Lists the all TODO items related to the list
    #
    # @return [Array<Todoable::Item>] a list of TODO items within the
    #  list.
    def items
      output = @todoable.request!("get", LIST_PATH, { :list_id => @id })
      output['items'].collect { |json_item|
        Item.new(@todoable, self, json_item)
      }
    end

    # Creates a new TODO item within the list
    #
    # @param [String] name The name of the list
    def new_item name
      body = {"item": {"name": name}}.to_json
      @todoable.request!("post", ITEMS_PATH, {:list_id => @id}, body)
    end
  end

  # Class that represents TODO Items
  class Item
    attr_accessor :name
    attr_accessor :id
    attr_accessor :finished_at

    # Create instances of the Item class
    #
    # @param [Todoable::Todoable] todoable Instance of the `Todoable`
    #  class that knows how to perform authenticated requests.
    #
    # @param [Todoable::List] list instance of the list this new TODO
    #  item will belong to
    #
    # @param [Hash] params The parameters of the item. The hash must
    #  contain the fields `name`, `id`, and `finished_at`.
    def initialize todoable, list, params
      @todoable = todoable
      @list = list
      @name = params['name']
      @id = params['id']
      @finished_at = params['finished_at']
    end

    # Marks the TODO item as finished
    def mark_finished
      params = {:list_id => @list.id, :item_id => @id}
      @todoable.request!("put", ITEM_FINISHED_PATH, params)
    end

    # Delete the TODO item from the list
    def delete
      params = {:list_id => @list.id, :item_id => @id}
      @todoable.request!("delete", ITEM_PATH, params)
    end
  end

  # Exception raised when any API requests are attempted before proper
  # authentication. (see #Todoable::authenticate)
  class NotAuthenticated < Exception
  end

  # Exception raised when the authentication fails.
  #
  # For the `/authenticate` endpoint, it means that user or password
  # are wrong. For the other endpoints it's raised because the token
  # could have expired.
  class AuthError < Exception
  end

  # Main class of the `Todoable` Web-API wrapper.
  class Todoable
    # Base URI for the HTTP API
    # @return [String] The base URI that will be used. See #initialize
    attr_accessor :api_base_uri

    # Create new instances of the Todoable class.
    #
    # @param [String, nil] api_uri Base URI for the API. If `nil` is
    #  passed, the default `http://todoable.teachable.tech` will be
    #  used.
    def initialize api_uri = nil
      @token = nil
      @api_base_uri = api_uri || "http://todoable.teachable.tech"
    end

    # Authenticate the session against the remote server and store
    # the authentication token for future requests.
    #
    # This must be the first method called after instantiating the
    # {Todoable::Todoable} class. All the other methods that access
    # other endpoints will fail with the {Todoable::AuthError}
    # exception otherwise.
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

    # Retrieve all the lists available for the authenticated user
    def lists
      request!("get", LISTS_PATH)["lists"].collect { |json_list|
        List.new(self, json_list)
      }
    end

    # Creates a new list
    #
    # @param [String] name The name of the new list
    def new_list name
      request!("post", LISTS_PATH, nil, {"list": {"name": name}}.to_json)
    end

    # Concatenates API paths to the base URI
    #
    # @param [String] path Path component of the endpoint to be
    #  concatenated to the base URI
    #
    # @param [Hash, nil] params Hash that contains parameters that
    #  should be replaced in the URI.
    #
    # @return [String] The full URI with all the provided parameters
    #  interpolated.
    #
    # @example Interpolate parameters
    #  todo = Todoable::Todoable.new "http://foo"
    #  todo.api_uri("/l/:id", { :id => 'af320e'}) #=> "http://foo/l/af320e"
    def api_uri(path, params = nil)
      p = path
      params.each {|k, v| p = p.gsub(/(:#{k.to_s})/, v.to_s)} if params
      URI.join(api_base_uri, p)
    end

    # Retrieve remote data via HTTP calls and attempts to parse the
    # response body as JSON
    #
    # @param [String] method HTTP method intended to be used. It can
    # only receive get, post, patch, put or delete.
    # @param [Hash, nil] params Parameters to be interpolated in the
    # URI path.
    # @param [String, nil] body Any content that is intended to be
    # sent in the body of the request.
    # @return [Object, String] Returns an Object when the response
    # body contains JSON data. Returns a String otherwise.
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

      # Automatically convert to JSON if the output is
      # convertible. The Web API unfortunately doesn't inform the
      # right Content-Type header in the response, and some endpoints
      # do not return JSON, thus the begin/rescue.
      begin
        JSON.parse(body) if body != nil && !body.empty?
      rescue JSON::ParserError
        body
      end
    end
  end
end
