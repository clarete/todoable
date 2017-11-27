# Todoable

Access the Todoable API by teachable using this simple ruby library.

Although the main goal of this project is to write a sleek API
wrapper, it also provides two other little niceties:

1. A local server to allow testing to happen without hitting the
   remote endpoint
2. A Nice and smooth Graphical User Interface built with [Ruby
   GTK](http://ruby-gnome2.osdn.jp/). There are instructions in how to
   run it bellow the API documentation. Here's a tease:

![GTK UI FTW!!!](https://github.com/clarete/todoable/blob/master/docs/screencap.gif?raw=true "Todoable-GTK")

## Installation & Usage

Before installing the ruby dependencies, you also need to have
`libyaml`. `rspec` depends on it I believe. To get the tests running,
run the following commands:

### System dependency
#### Debian GNU/Linux & compatibles
```bash
$ sudo apt install libyaml-dev
```
#### macos
```bash
$ brew install libyaml
```
### Install Ruby dependencies & run the tests

The following commands will work in both Debian compatible systems and macos

```bash
$ bundle exec install
$ bundle exec rspec
```

### Web API Examples

#### Authentication

The Todoable API requires authentication. That can be done by
informing *user* and *password* to the constructor of the `Todoable`
class:

```ruby
require 'todoable'
todo = Todoable::Todoable.new
todo.authenticate "user", "password"
```

If you call any other method from the `Todoable::Todoable` class
without authenticating, the exception `NotAuthenticated` will be
raised.

#### Create new lists

After instantiating an instance of the `Todoable::Todoable` class, a
new list can be created like the following:

```ruby
todo.new_list("Fun things")
```

#### Retrieve all lists

To retrieve all lists just use the `Todoable::Todoable.lists` method
as following:

```ruby
todo.lists()
```

The output will be a Ruby list containing instances of the class
`Todoable::List`.

#### Update list title

After a list is created it's also possible to update its title. If you
have a list instance acquired the `Todoable::Todoable::lists()`
method, you can just call the method `Todoable::List::update()`
passing the new name as the only parameter:

```ruby
todo.new_list('foo')
puts todo.lists()[0].name # ===> foo

todo.lists()[0].update('bar')
puts todo.lists()[0].name # ===> bar
```

#### Delete a list
```ruby
todo = Todoable::Todoable.new
todo.authenticate "user", "password"
todo.lists.length #=> 0

todo.new_list 'foo'
todo.lists.length #=> 1

todo.lists[0].delete
todo.lists.length #=> 0
```

#### Create a TODO item within a list

```ruby
todo = Todoable::Todoable.new
todo.authenticate "user", "password"

todo.new_list 'Plan vacation'
todo.lists[0].items.length #=> 0

todo.lists[0].new_item 'Reserve tickets'
todo.lists[0].items.length #=> 1
todo.lists[0].items[0].name #=> 'Reserve tickets'
```

#### Base API URI

If the `Todoable::Todoable` class is instantiated with no parameters,
the base API URI defaults to `http://todoable.teachable.tech`. But if
you need to provide a different host, just instantiate the class
informing the host you want to target:

```ruby
require 'todoable'

# Default endpoint
todo0 = Todoable::Todoable.new

# Custom endpoint
todo1 = Todoable::Todoable.new "http://localhost:8080"
```

### Documentation

This project uses [YARD](https://yardoc.org/) to generate a nice HTML
output of the API documentation. It's indeed available online in the
[Github pages](https://clarete.github.io/todoable) of this project but
here's how it can be generated locally as well:

```bash
$ bundle exec rake yard
```

### Local Server

The local server is a simple [Sinatra](sinatrarb.com/) application
that offers all the endpoints that the remote API provides. It's very
useful for testing things locally. Here's how to run it:

```bash
$ ./bin/localserver
```

### Graphical User Interface

#### System dependency

##### Debian GNU/Linux & compatibles
```bash
$ sudo apt install libgtk-3-dev
```
##### macos
```bash
$ brew install gtk+3 hicolor-icon-theme
```

#### Ruby dependencies
```bash
$ gem install gtk3
```

#### See it running
```bash
$ ./bin/todoable-gtk
```

### API Coverage

This gem exposes the following API endpoints:

 * [X] POST   `/authenticate`
 * [X] GET    `/lists`
 * [X] POST   `/lists`
 * [X] GET    `/lists/:id`
 * [X] PATCH  `/lists/:id`
 * [X] DELETE `/lists/:id`
 * [X] POST   `/lists/:list_id/items`
 * [X] PUT    `/lists/:list_id/items/:item_id/finish`
 * [X] DELETE `/lists/:list_id/items/:item_id`

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake spec` to run the tests. You can also run
`bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/clarete/todoable. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## License: GPLv3

Copyright (C) 2017  Lincoln Clarete <lincoln@clarete.li>

The project license is specified in COPYING and COPYING.LESSER.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License (LGPL) as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Code of Conduct

Everyone interacting in the Todoable project’s codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code
of conduct](https://github.com/clarete/todoable/blob/master/CODE_OF_CONDUCT.md).
