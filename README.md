# OptionsHash

An OptionsHash is a definition of required and optional keys in an options hash

## Installation

Add this line to your application's Gemfile:

    gem 'options_hash'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install options_hash

## Usage

A simple use case goes something like this:

```ruby
require 'net/http'

def http_get options
  options = OptionsHash.parse(options) do
    required :host, :path
    optional :port, default: 80
  end
  Net::HTTP.get(options.host, options.path, options.port)
end

http_get
# => ArgumentError: wrong number of arguments (0 for 1)
http_get({})
# => ArgumentError: required options: :host, :path
http_get(host: 'google.com')
# => ArgumentError: required options: :path
http_get(host: 'google.com', path: '/')
# => "<HTML><HEAD><meta ht..."
http_get(host: 'google.com', path: '/', port: 81)
# => Net::HTTPRequestTimeOut
```

A possibly more common use case:

```ruby
class Person
  class Options < OptionsHash
    required :name
    optional :age, default: 31
  end

  def initialize options
    @options = Options.parse(options)
  end
  attr_reader :options
end

me = Person.new({}) # => ArgumentError: required options: :name

me = Person.new(name: 'Jared Grippe')
me.options.name    # => "Jared Grippe"
me.options.age     # => 31
me.options.to_hash # => {:name=>"Jared Grippe", :age=>31}

me = Person.new(name: 'Jared Grippe', age: 25)
me.options.name    # => "Jared Grippe"
me.options.age     # => 25
```

Advanced usage:

```ruby
class PersonOptions < OptionsHash
  required :name
  optional :favorite_color
  optional :species, default: :human
end

PersonOptions.options # => {
  # :name=>required without default,
  # :favorite_color=>optional without default,
  # :species=>optional with default}

PersonOptions[:name]                   # => required without default
PersonOptions[:name].required?         # => true
PersonOptions[:name].has_default?      # => false
PersonOptions[:name].has_default_proc? # => false
PersonOptions[:name].default           # => nil

PersonOptions.parse({}) # ArgumentError: required options: :name

PersonOptions.parse(name: 'Steve')
# => #<PersonOptions {:name=>"Steve", :favorite_color=>nil, :species=>:human}>

PersonOptions.parse(name: 'Steve', favorite_color: 'blue')
# => #<PersonOptions {:name=>"Steve", :favorite_color=>"blue", :species=>:human}>

PersonOptions.parse(name: 'Steve', species: :robot)
# => #<PersonOptions {:name=>"Steve", :favorite_color=>"blue", :species=>:robot}>

options = PersonOptions.parse(name: 'Steve', species: :robot)

options.name           # => "Steve"
options.favorite_color # => nil
options.species        # => :robot

options.given? :name           # => true
options.given? :favorite_color # => false
options.given? :species        # => true

options.to_hash # => {:name=>"Steve", :favorite_color=>nil, :species=>:robot}

```




All options can take a block to determine their default value:

```ruby
class PersonOptions < OptionsHash
  required(:first_name, :last_name) { |name| name.to_sym }
  optional :full_name, default: ->{ "#{first_name} #{last_name}" }
end

PersonOptions
# => PersonOptions(required: [:first_name, :last_name], optional: [:full_name])

options = PersonOptions.parse(first_name: 'Jared', last_name: 'Grippe')
# => #<PersonOptions {:first_name=>:Jared, :last_name=>:Grippe, :full_name=>"Jared Grippe"}>

options.given_options
# => {:first_name=>"Jared", :last_name=>"Grippe"}

options[:first_name] # => :Jared
options[:last_name]  # => :Grippe
options[:full_name]  # => "Jared Grippe"
```

Option hashes can inherit from other option hashes

```ruby
class AnimalOptions < OptionsHash
  required :species
  optional :alive, default: true
end
class DogOptions < AnimalOptions
  required :name, :breed
end

AnimalOptions
# => AnimalOptions(required: [:species], optional: [:alive])

DogOptions
# => DogOptions(required: [:breed, :name, :species], optional: [:alive])

DogOptions[:alive].default # => true
```




## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
