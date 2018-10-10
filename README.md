# netstring.cr

A Crystal implementation of [djb's netstrings](https://cr.yp.to/proto/netstrings.txt).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  netstring:
    github: woodruffw/netstring.cr
```

## Usage

```crystal
require "netstring"

# From a source string:
ns = Netstring.parse "3:foo,"
ns.size # => 3
ns.data # => Bytes[102, 111, 111]
ns.to_s # => "foo"

# From an IO:
ns = Netstring.parse IO::Memory.new("bar")
```

## Contributing

1. Fork it (<https://github.com/woodruffw/netstring/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [woodruffw](https://github.com/woodruffw) William Woodruff - creator, maintainer
