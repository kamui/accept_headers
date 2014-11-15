[![Build Status](https://travis-ci.org/kamui/accept_headers.png)](https://travis-ci.org/kamui/accept_headers)
[![Code Climate](https://codeclimate.com/github/kamui/accept_headers/badges/gpa.svg)](https://codeclimate.com/github/kamui/accept_headers)
[![Test Coverage](https://codeclimate.com/github/kamui/accept_headers/badges/coverage.svg)](https://codeclimate.com/github/kamui/accept_headers)

# AcceptHeaders

**AcceptHeaders** is a ruby library that does content negotiation and parses and sorts http accept headers.

Some features of the library are:

  * Strict adherence to [RFC 2616][rfc], specifically [section 14][rfc-sec14]
  * Full support for the [Accept][rfc-sec14-1], [Accept-Encoding][rfc-sec14-3],
    and [Accept-Language][rfc-sec14-4] HTTP request headers
  * `Accept-Charset` is not supported because it's [obsolete](https://developer.mozilla.org/en-US/docs/Web/HTTP/Content_negotiation#The_Accept-Charset.3A_header)
  * Parser tested against all IANA registered [media types][iana-media-types]
  * A comprehensive [spec suite][spec] that covers many edge cases

This library is optimistic when parsing headers. If a specific media type, encoding, charset, or language can't be parsed, is in an invalid format, or contains invalid characters, it will skip that specific entry when constructing the sorted list. If a `q` value can't be read or is in the wrong format (more than 3 decimal places), it will default it to `0.001` so it still has a chance to match. Lack of an explicit `q` value of course defaults to 1.

[rfc]: http://www.w3.org/Protocols/rfc2616/rfc2616.html
[rfc-sec14]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
[rfc-sec14-1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
[rfc-sec14-3]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
[rfc-sec14-4]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
[iana-media-types]: https://www.iana.org/assignments/media-types/media-types.xhtml
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

`AcceptHeaders::MediaType::Negotiator` is a class that is initialized with an `Accept` header string and will internally store an array of `MediaType`s in descending order according to the spec, which takes into account `q` value, `type`/`subtype` and `params` specificity.

```ruby
media_types = AcceptHeaders::MediaType::Negotiator.new("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5")

media_types.list

# Returns:

[
  AcceptHeaders::MediaType.new('text', 'html', params: { 'level' => '1' }),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.7),
  AcceptHeaders::MediaType.new('*', '*', q: 0.5),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.4, params: { 'level' => '2' }),
  AcceptHeaders::MediaType.new('text', '*', q: 0.3)
]
```

`#negotiate` takes a string of media types supported (by your API or route/controller) and returns the best match as a `MediaType`. This will first check the available list for any matching media types with a `q` of 0 and return `nil` if there is a match. Then it'll look to the highest `q` values and look for matches in descending `q` value order and return the first match account for wildcards.

```ruby
media_type.negotiate('text/html')

# Returns:

AcceptHeaders::MediaType.new('text', 'html', params: { 'level' => '1' })
```

### Accept-Encoding

`AcceptHeader::Charset::Encoding`:

```ruby
encodings = AcceptHeaders::Encoding::Negotiator.new("deflate; q=0.5, gzip, compress; q=0.8, identity")

encodings.list

# Returns:

[
  AcceptHeaders::Encoding.new('gzip'),
  AcceptHeaders::Encoding.new('identity'),
  AcceptHeaders::Encoding.new('compress', q: 0.8),
  AcceptHeaders::Encoding.new('deflate', q: 0.5)
]
```

`#negotiate`:

```ruby
encodings.negotiate('identity')

# Returns:

AcceptHeaders::Encoding.new('identity')
```

### Accept-Language

`Accept::Language::Negotiator`:

```ruby
languages = AcceptHeaders::Language::Negotiator.new("en-*, en-us, *;q=0.8")

languages.list

# Returns:

[
  AcceptHeaders::Language.new('en', 'us'),
  AcceptHeaders::Language.new('en', '*'),
  AcceptHeaders::Language.new('*', '*', q: 0.8)
]
```

`#negotiate`:

```ruby
languages.negotiate('en-us')

# Returns:

AcceptHeaders::Language.new('en', 'us')
```

## Todo

* Write rack middleware
* More edge case tests

## Contributing

1. Fork it ( https://github.com/[my-github-username]/accept_headers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
