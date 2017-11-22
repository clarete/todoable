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
end

RSpec.describe "Authentication" do
  it "should be able to authenticate" do
    # Given an instance of the API wrapper
    todoable = Todoable::Todoable.new("user", "password")

    # And given that the endpoint is stubbed
    stub_request(:post, todoable.api_uri(Todoable::AUTH_PATH))
      .with(headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'})

    # When the client tries to authenticate
    todoable.authenticate!

    # Then it should retrieve the auth token
    expect(WebMock).to(
      have_requested(:post, todoable.api_uri(Todoable::AUTH_PATH))
        .with(headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'}))
  end
end
