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

This library is optimistic when parsing headers. If a specific media type, encoding, or language can't be parsed, is in an invalid format, or contains invalid characters, it will skip that specific entry when constructing the sorted list. If a `q` value can't be read or is in the wrong format (more than 3 decimal places), it will default it to `0.001` so it still has a chance to match. Lack of an explicit `q` value of course defaults to 1.

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

`#negotiate` takes an array of media range strings supported (by your API or route/controller) and returns a hash where the `supported` key contains the array element matched and the `matched` key containing a `MediaType` that was matched in the `Negotiator`s internal list.

This will first check the available list for any matching media types with a `q` of 0 and skip any matches. It does this because the RFC specifies that if the `q` value is 0, then content with this parameter is `not acceptable`. Then it'll look to the highest `q` values and look for matches in descending `q` value order and return the first match (accounting for wildcards). Finally, if there are no matches, it returns `nil`.

```ruby
# The same media_types variable as above
media_types.negotiate(['text/html', 'text/plain'])

# Returns:

{
  supported: 'text/html',
  matched:    AcceptHeaders::MediaType.new('text', 'html', q: 1, params: { 'level' => '1' })
}
```

`#accept?`:

```ruby
media_types.accept?('text/html') # true
```

### Accept-Encoding

`AcceptHeader::Encoding::Encoding`:

```ruby
encodings = AcceptHeaders::Encoding::Negotiator.new("deflate; q=0.5, gzip, compress; q=0.8, identity")

encodings.list

# Returns:

[
  AcceptHeaders::Encoding.new('gzip'),
  AcceptHeaders::Encoding.new('compress', q: 0.8),
  AcceptHeaders::Encoding.new('deflate', q: 0.5)
]
```

`#negotiate`:

```ruby
encodings.negotiate(['gzip', 'compress'])

# Returns:

{
  supported: 'gzip',
  matched:    AcceptHeaders::Encoding.new('gzip'))
}
```

`#accept?`:

```ruby
encodings.accept?('gzip') # true

# Identity is accepted as long as it's not explicitly rejected 'identity;q=0'

encodings.accept?('identity') # true
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
languages.negotiate(['en-us', 'zh-Hant'])

# Returns:

{
  supported: 'en-us',
  matched:    AcceptHeaders::Language.new('en', 'us'))
}
```

`#accept?`:

```ruby
languages.accept?('en-gb') # true
```

## TODO

* Write rack middleware
* More edge case tests
* Add rdoc

## Contributing

1. Fork it ( https://github.com/[my-github-username]/accept_headers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
