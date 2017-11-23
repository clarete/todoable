# Todoable

Access the Todoable API by teachable using this simple ruby library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'todoable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install todoable

## What is covered

 * [X] GET    `/lists`
 * [X] POST   `/lists`
 * [X] GET    `/lists/:id`
 * [X] PATCH  `/lists/:id`
 * [X] DELETE `/lists/:id`
 * [X] POST   `/lists/:list_id/items`
 * [X] PUT    `/lists/:list_id/items/:item_id/finish`
 * [X] DELETE `/lists/:list_id/items/:item_id`

## Usage

### Authentication

The Todoable API requires authentication. That can be done by
informing *user* and *password* to the constructor of the `Todoable`
class:

```ruby
require 'todoable'

todo = Todoable::Todoable.new("user", "password")
```

### Create new lists

After instantiating an instance of the `Todoable::Todoable` class, a
new list can be created like the following:

```ruby
todo.new_list("Fun things")
```

### Retrieve all lists

To retrieve all lists just use the `Todoable::Todoable.lists` method
as following:

```ruby
todo.lists()
```

The output will be a Ruby list containing instances of the class
`Todoable::List`.

### Update list title

After a list is created it's also possible to update its title. If you
have a list instance acquired the `Todoable::Todoable::lists()`
method, you can just call the method `Todoable::List::update()`
passing the new name as the only parameter:

```ruby
test_todo = Todoable::Todoable.new("user", "password")
test_todo.new_list('foo')

puts test_todo.lists()[0].name # ===> foo

test_todo.lists()[0].update('bar')

puts test_todo.lists()[0].name # ===> bar

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clarete/todoable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Todoable project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/clarete/todoable/blob/master/CODE_OF_CONDUCT.md).
