RSpec.describe "Test test setup" do
  it "has a version number" do
    expect(Todoable::VERSION).not_to be nil
  end
end

RSpec.describe "Build Endpoints" do
  it "has an API endpoint accessor" do
    todoable = Todoable::Todoable.new("user", "password")
    expect(todoable.api_base_uri).to eql("http://todoable.teachable.tech")
  end

  it "builds URIs for different API methods" do
    todoable = Todoable::Todoable.new("user", "password")
    expect(todoable.api_uri(Todoable::AUTH_PATH)).to(
      eql(URI("http://todoable.teachable.tech/api/authenticate")))
  end

  it "builds endpoints with parameters" do
    todoable = Todoable::Todoable.new("user", "password")
    expect(todoable.api_uri(Todoable::LIST_PATH, {:list_id => 10})).to(
      eql(URI("http://todoable.teachable.tech/api/lists/10")))
  end
end

def default_headers
  {'Accept' => 'application/json', 'Content-Type' => 'application/json'}
end

def auth_headers(token)
  {'Accept' => 'application/json',
   'Content-Type' => 'application/json',
   'Authorization' => "Token token=\"#{token}\""}
end

RSpec.describe "Authentication" do
  it "access the authentication end point" do
    # Given an instance of the API wrapper
    todoable = Todoable::Todoable.new("user", "password")

    # And given that the endpoint is stubbed
    stub_request(:post, todoable.api_uri(Todoable::AUTH_PATH))
      .with(headers: default_headers)
      .to_return(body: '{ "token": "foo" }')

    # When the client tries to authenticate
    todoable.authenticate!

    # Then it should retrieve the auth token
    expect(WebMock).to(
      have_requested(:post, todoable.api_uri(Todoable::AUTH_PATH))
        .with(headers: default_headers))
  end

  it "use the authentication token in other requests" do
    # Given an instance of the API wrapper
    todoable = Todoable::Todoable.new("user", "password")

    # And given that the authentication endpoint is stubbed
    stub_request(:post, todoable.api_uri(Todoable::AUTH_PATH))
      .with(headers: default_headers)
      .to_return(body: '{ "token": "Very Secret Token" }')

    # And given that the lists endpoint is also stubbed
    stub_request(:get, todoable.api_uri(Todoable::LISTS_PATH))
      .with(headers: auth_headers('Very Secret Token'))
      .to_return(body: '[]')

    # When it tries to retrieve lists for example
    todoable.lists()

    # Then it should hit the API to retrieve the lists
    expect(WebMock).to(
      have_requested(:get, todoable.api_uri(Todoable::LISTS_PATH))
        .with(headers: auth_headers('Very Secret Token')))
  end
end


RSpec.describe "Lists" do
  before do
    # Instance that will be the target of all these tests
    @todoable = Todoable::Todoable.new("user", "password")

    # Stub the request to the auth endpoint that is needed by all
    # other tests in this class
    stub_request(:post, @todoable.api_uri(Todoable::AUTH_PATH))
      .with(headers: default_headers)
      .to_return(body: '{ "token": "token" }')
  end

  it "works with no lists" do
    # Given that the lists endpoint is stubbed to return no lists
    stub_request(:get, @todoable.api_uri(Todoable::LISTS_PATH))
      .with(headers: auth_headers('token'))
      .to_return(body: '[]')

    # When it tries to retrieve lists
    lists = @todoable.lists()

    # Then it should return just an empty list
    expect(lists).to eql([])
  end

  it "retrieve lists" do
    # Given that the lists endpoint is stubbed to return a single list
    stub_request(:get, @todoable.api_uri(Todoable::LISTS_PATH))
      .with(headers: auth_headers('token'))
      .to_return(body: '[{"name": "Urgent Things",' \
                       '  "src":  "http://todoable.teachable.tech/api/lists/:list_id",' \
                       '  "id":  44}]')

    # When it tries to retrieve lists
    lists = @todoable.lists()

    # Then it should return just an empty list
    expect(lists.length).to eql(1)
    expect(lists[0]).to be_instance_of(Todoable::List)
    expect(lists[0].name).to eql("Urgent Things")
    expect(lists[0].src).to eql("http://todoable.teachable.tech/api/lists/:list_id")
    expect(lists[0].id).to eql(44)
  end

  it "create new lists" do
    # Given that the method POST of the lists endpoint is stubbed like
    # the following:
    stub_request(:post, @todoable.api_uri(Todoable::LISTS_PATH))
      .with(headers: auth_headers('token'))
      .to_return(status: 200)

    # When a new list is added to the todo instance
    @todoable.new_list("Fun things")

    # Then the post should have been performed against the lists path
    expect(WebMock).to(
      have_requested(:post, @todoable.api_uri(Todoable::LISTS_PATH))
        .with(headers: auth_headers('token'),
              body: {"list": {"name": "Fun things"}}.to_json))
  end

  it "updates a list" do
    # Given a list
    list = Todoable::List.new @todoable, {
      'name' => 'foo',
      'src' => @todoable.api_uri(Todoable::LIST_PATH, {:list_id => 42}),
      'id' => 42
    }

    # And given that the method PATCH of the lists endpoint is stubbed
    # like the following:
    stub_request(:patch, list.src)
      .with(headers: auth_headers('token'))
      .to_return(status: 200)

    # When the list is updated
    list.update("bar")

    # Then it's expected that the endpoint that updates lists is hit
    # with the right payload
    expect(WebMock).to(
      have_requested(:patch, list.src).with(
        headers: auth_headers('token'),
        body: {"list": {"name": "bar"}}.to_json))
  end

  it "deletes a list" do
    # Given a list
    list = Todoable::List.new @todoable, {
      'name' => 'foo',
      'src' => @todoable.api_uri(Todoable::LIST_PATH, {:list_id => 42}),
      'id' => 42
    }

    # And given that the method DELETE of the lists endpoint is stubbed
    # like the following:
    stub_request(:delete, list.src)
      .with(headers: auth_headers('token'))
      .to_return(status: 200)

    # When the list is deleted
    list.delete()

    # Then it's expected to hit the API in the right endpoint
    expect(WebMock).to(
      have_requested(:delete, list.src).with(headers: auth_headers('token')))
  end
end

RSpec.describe "List Items" do
  before do
    # Instance that will be the target of all these tests
    @todoable = Todoable::Todoable.new("user", "password")

    # Stub the request to the auth endpoint that is needed by all
    # other tests in this class
    stub_request(:post, @todoable.api_uri(Todoable::AUTH_PATH))
      .with(headers: default_headers)
      .to_return(body: '{ "token": "token" }')
  end

  it "Enumerates items from a list" do
    # Given a list
    list = Todoable::List.new @todoable, {
      'name' => "Urgent Things",
      'src' => @todoable.api_uri(Todoable::LIST_PATH, {:list_id => 42}),
      'id' => 42
    }

    # And given that the method GET of the endpoint that lists items
    # is stubbed like the following:
    stub_request(:get, list.src)
      .with(headers: auth_headers('token'))
      .to_return(status: 200, body: {
        "list" => {
          "name" => "Urgent Things",
          "items" => [{
            "name" => "Feed the cat",
            "finished_at" => nil,
            "src" => "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
            "id" => 10
          }, {
            "name" => "Get cat food",
            "finished_at" => nil,
            "src" => "http://todoable.teachable.tech/api/lists/:list_id/items/:item_id",
            "id" => 20
          }]
        }
      }.to_json)

    # When the items of a list are requested
    items = list.items()

    # Then it's expected to hit the endpoint that lists items of a
    # list
    expect(WebMock).to(
      have_requested(:get, list.src).with(
        headers: auth_headers('token')))

    # And then the items list should contain two elements of the
    # Todoable::Item type
    expect(items.length).to eql(2)
    expect(items[0]).to be_instance_of(Todoable::Item)
    expect(items[0].name).to eql("Feed the cat")
    expect(items[0].id).to eql(10)
    expect(items[1]).to be_instance_of(Todoable::Item)
    expect(items[1].name).to eql("Get cat food")
    expect(items[1].id).to eql(20)
  end

  it "creates new items on a list" do
    # Given a list
    list = Todoable::List.new @todoable, {'name' => "Urgent Things", 'id' => 42}

    # And given that the method POST of the endpoint that creates list
    # items is stubbed like the following:
    uri = @todoable.api_uri(Todoable::ITEMS_PATH, {:list_id => 42})
    stub_request(:post, uri)
      .with(headers: auth_headers('token'))
      .to_return(status: 201)

    # When a new item is created
    list.new_item("Sing with the birds")

    # Then it's expected that the endpoint that creates list items is
    # hit with the right payload
    expect(WebMock).to(
      have_requested(:post, uri).with(
        headers: auth_headers('token'),
        body: {"item": {"name": "Sing with the birds"}}.to_json))
  end

  it "marks TODO items as finished" do
    # Given a list & a TODO item
    list = Todoable::List.new @todoable, {'name' => "Urgent Things", 'id' => 42}
    item = Todoable::Item.new @todoable, list, {'name' => "Feed the birds", 'id' => 10}

    # And given that the method POST of the endpoint that creates list
    # items is stubbed like the following:
    uri = @todoable.api_uri(Todoable::ITEM_FINISHED_PATH, {:list_id => 42, :item_id => 10})
    stub_request(:put, uri)
      .with(headers: auth_headers('token'))
      .to_return(status: 200)

    # When an item is marked as finished
    item.mark_finished

    # Then it's expected that the endpoint that marks list items as
    # finished is hit
    expect(WebMock).to(
      have_requested(:put, uri).with(headers: auth_headers('token')))
  end

  it "deletes TODO items" do
    # Given a list & a TODO item
    list = Todoable::List.new @todoable, {'name' => "Urgent Things", 'id' => 42}
    item = Todoable::Item.new @todoable, list, {'name' => "Feed the birds", 'id' => 10}

    # And given that the method DELETE of the endpoint that deletes
    # list items is stubbed like the following:
    uri = @todoable.api_uri(Todoable::ITEM_PATH, {:list_id => 42, :item_id => 10})
    stub_request(:delete, uri)
      .with(headers: auth_headers('token'))
      .to_return(status: 204)

    # When the TODO item is deleted
    item.delete()

    # Then it's expected to hit the API in the right endpoint
    expect(WebMock).to(
      have_requested(:delete, uri).with(headers: auth_headers('token')))
  end
end
