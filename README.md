[![Build Status](https://travis-ci.org/kamui/accept_headers.png)](https://travis-ci.org/kamui/accept_headers)
[![Code Climate](https://codeclimate.com/github/kamui/accept_headers/badges/gpa.svg)](https://codeclimate.com/github/kamui/accept_headers)
[![Test Coverage](https://codeclimate.com/github/kamui/accept_headers/badges/coverage.svg)](https://codeclimate.com/github/kamui/accept_headers)

# AcceptHeaders

**AcceptHeaders** is a ruby library that parses and sorts http accept headers.

Some features of the library are:

  * Strict adherence to [RFC 2616][rfc], specifically [section 14][rfc-sec14]
  * Full support for the [Accept][rfc-sec14-1], [Accept-Charset][rfc-sec14-2],
    [Accept-Encoding][rfc-sec14-3], and [Accept-Language][rfc-sec14-4] HTTP
    request headers
  * A comprehensive [spec suite][spec] that covers many edge cases

This library is optimistic when parsing headers. If a specific media type, encoding, charset, or language can't be parsed, is in an invalid format, or contains invalid characters, it will skip that specific entry when constructing the sorted list. If a `q` value can't be read or is in the wrong format (more than 3 decimal places), it will default it to `0.001` so it still has a chance to match. Lack of an explicit `q` value of course defaults to 1.

[rfc]: http://www.w3.org/Protocols/rfc2616/rfc2616.html
[rfc-sec14]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
[rfc-sec14-1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
[rfc-sec14-2]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.2
[rfc-sec14-3]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
[rfc-sec14-4]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
[spec]: http://github.com/kamui/accept_headers/tree/master/spec/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'accept_headers'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install accept_headers

## Usage

### Accept

`AcceptHeaders` can parse the `Accept` header and return an array of `MediaType`s in descending order according to the spec, which takes into account `q` value, `type`/`subtype` and `params` specificity.

```ruby
AcceptHeaders::MediaType.parse("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5")
```

Will generate this equivalent array:

```ruby
[
  AcceptHeaders::MediaType.new('text', 'html', params: { 'level' => '1' }),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.7),
  AcceptHeaders::MediaType.new('*', '*', q: 0.5),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.4, params: { 'level' => '2' }),
  AcceptHeaders::MediaType.new('text', '*', q: 0.3)
]
```

`#negotiate` takes an array of `MediaType`s available (from the browser) and an array of `MediaTypes`s supported (by your API or route/controller) and returns the best match. This will first check the available list for any matching media types with a `q` of 0 and return `nil` if there is a match. Then it'll look to the highest `q` values and look for matches in descending `q` value order and return the first match account for wildcards.

```ruby
available = [
  AcceptHeaders::MediaType.new('text', 'html', params: { 'level' => '1' }),
  AcceptHeaders::MediaType.new('text', 'html'),
  AcceptHeaders::MediaType.new('text', '*'),
  AcceptHeaders::MediaType.new('*', '*')
]
match = AcceptHeaders::MediaType.new('text', 'html')
AcceptHeaders::MediaType.negotiate(available, [match])

# Returns:

AcceptHeaders::MediaType.new('text', 'html', params: { 'level' => '1' })
```

### Accept-Charset

Parsing `Charset`:

```ruby
AcceptHeaders::Charset.parse("us-ascii; q=0.5, iso-8859-1, utf-8; q=0.8, macintosh")

# Generates:

[
  AcceptHeaders::Charset.new('iso-8859-1'),
  AcceptHeaders::Charset.new('macintosh'),
  AcceptHeaders::Charset.new('utf-8', q: 0.8),
  AcceptHeaders::Charset.new('us-ascii', q: 0.5)
]
```

`#negotiate`:

```ruby
available = [
  AcceptHeaders::Charset.new('iso-8859-1'),
  AcceptHeaders::Charset.new('macintosh'),
  AcceptHeaders::Charset.new('utf-8', q: 0.8),
  AcceptHeaders::Charset.new('us-ascii', q: 0.5)
]
match = Charset.new('iso-8859-1')
AcceptHeaders::Charset.negotiate(available, [match])

# Returns

AcceptHeaders::Charset.new('iso-8859-1')
```

### Accept-Encoding

Parsing `Encoding`:

```ruby
AcceptHeaders::Encoding.parse("deflate; q=0.5, gzip, compress; q=0.8, identity")

# Generates:

[
  AcceptHeaders::Encoding.new('gzip'),
  AcceptHeaders::Encoding.new('identity'),
  AcceptHeaders::Encoding.new('compress', q: 0.8),
  AcceptHeaders::Encoding.new('deflate', q: 0.5)
]
```

`#negotiate`:

```ruby
available = [
  AcceptHeaders::Encoding.new('gzip'),
  AcceptHeaders::Encoding.new('identity'),
  AcceptHeaders::Encoding.new('compress', q: 0.8),
  AcceptHeaders::Encoding.new('deflate', q: 0.5)
]
match = Encoding.new('identity')
AcceptHeaders::Encoding.negotiate(available, [match])

# Returns:
AcceptHeaders::Encoding.new('identity')
```

### Accept-Language

Parsing `Language`:

```ruby
AcceptHeaders::Language.parse("en-*, en-us, *;q=0.8")

# Generates:

[
  AcceptHeaders::Language.new('en', 'us'),
  AcceptHeaders::Language.new('en', '*'),
  AcceptHeaders::Language.new('*', '*', q: 0.8)
]
```

`#negotiate`:

```ruby
available = [
  AcceptHeaders::Language.new('en', 'us'),
  AcceptHeaders::Language.new('en', '*'),
  AcceptHeaders::Language.new('*', '*', q: 0.8)
]
match = AcceptHeaders::Language.new('en', 'us')
AcceptHeaders::Language.negotiate(available, [match])

# Returns:

AcceptHeaders::Language.new('en', 'us')
```

## Todo

* Write rack middleware
* More edge cast tests

## Contributing

1. Fork it ( https://github.com/[my-github-username]/accept_headers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
