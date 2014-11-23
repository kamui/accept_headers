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
  * Parser tested against all IANA registered [media types][iana-media-types] and [encodings][iana-encodings]
  * A comprehensive [spec suite][spec] that covers many edge cases

This library is optimistic when parsing headers. If a specific media type, encoding, or language can't be parsed, is in an invalid format, or contains invalid characters, it will skip that specific entry when constructing the sorted list. If a `q` value can't be read or is in the wrong format (more than 3 decimal places), it will default it to `0.001` so it still has a chance to match. Lack of an explicit `q` value of course defaults to 1.

[rfc]: http://www.w3.org/Protocols/rfc2616/rfc2616.html
[rfc-sec14]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
[rfc-sec14-1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
[rfc-sec14-3]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
[rfc-sec14-4]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
[iana-media-types]: https://www.iana.org/assignments/media-types/media-types.xhtml
[iana-encodings]: https://www.iana.org/assignments/http-parameters/http-parameters.xml#content-coding
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

`AcceptHeaders::MediaType::Negotiator` is a class that is initialized with an `Accept` header string and will internally store an array of `MediaType`s in descending order according to the spec, which takes into account `q` value, `type`/`subtype` and `extensions` specificity.

```ruby
accept_header = 'Accept: text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5'
media_types = AcceptHeaders::MediaType::Negotiator.new(accept_header)

media_types.list

# Returns:

[
  AcceptHeaders::MediaType.new('text', 'html', extensions: { 'level' => '1' }),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.7),
  AcceptHeaders::MediaType.new('*', '*', q: 0.5),
  AcceptHeaders::MediaType.new('text', 'html', q: 0.4, extensions: { 'level' => '2' }),
  AcceptHeaders::MediaType.new('text', '*', q: 0.3)
]
```

`#negotiate` takes an array of media range strings supported (by your API or route/controller) and returns the best supported `MediaType` and the `extensions` params from the matching internal media type.

This will first check the available list for any matching media types with a `q` of 0 and skip any matches. It does this because the RFC specifies that if the `q` value is 0, then content with this parameter is `not acceptable`. Then it'll look to the highest `q` values and look for matches in descending `q` value order and return the first match (accounting for wildcards). Finally, if there are no matches, it returns `nil`.

```ruby
# The same media_types variable as above
media_types.negotiate(['text/html', 'text/plain'])

# Returns this equivalent:

AcceptHeader::MediaType.new('text', 'html', extensions: { 'level' => '1' })
```

It returns the matching `MediaType`, so you can see which one matched and also access the `extensions` params. For example, if you wanted to put your API version in the extensions, you could then retrieve the value.

```ruby
versions_header = 'Accept: application/json;version=2,application/json;version=1;q=0.8'
media_types = AcceptHeaders::MediaType::Negotiator.new(versions_header)

m = media_types.negotiate('application/json')
puts m.extensions['version'] # returns '2'
```

`#accept?`:

```ruby
media_types.accept?('text/html') # true
```

### Accept-Encoding

`AcceptHeader::Encoding::Encoding`:

```ruby
accept_encoding = 'Accept-Encoding: deflate; q=0.5, gzip, compress; q=0.8, identity'
encodings = AcceptHeaders::Encoding::Negotiator.new(accept_encoding)

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

# Returns this equivalent:

AcceptHeader::Encoding.new('gzip')
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
accept_language = 'Accept-Language: en-*, en-us, *;q=0.8'
languages = AcceptHeaders::Language::Negotiator.new(accept_language)

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

# Returns this equivalent:

AcceptHeaders::Language.new('en', 'us')
```

`#accept?`:

```ruby
languages.accept?('en-gb') # true
```

## Rack Middleware

Add the middleware:

```ruby
require 'accept_headers/middleware'
use AcceptHeaders::Middleware
run YourApp
```

Simple way to set the content response headers based on the request accept headers and the supported media types, encodings, and languages provided by the app or route.

```ruby
class YourApp
  def initialize(app)
    @app = app
  end

  def call(env)
    # List your arrays of supported media types, encodings, languages. This can be global or per route/controller
    supported_media_types = %w[application/json application/xml text/html text/plain]
    supported_encodings = %w[gzip identify]
    supported_languages = %w[en-US en-GB]

    # Call the Negotiators and pass in the supported arrays and it'll return the best match
    matched_media_type = env["accept_headers.media_types"].negotiate(supported_media_types)
    matched_encoding = env["accept_headers.encodings"].negotiate(supported_encodings)
    matched_language = env["accept_headers.languages"].negotiate(supported_languages)

    # Set a default, in this case an empty string, in case of a bad header that cannot be parsed
    # The return value is a MediaType, Encoding, or Language depending on the case:
    # On MediaType, you can call #type ('text'), #subtype ('html'), #media_range ('text/html') to get the stringified parts
    # On Encoding, you can call #encoding to get the string encoding ('gzip')
    # On Language, you can call #primary_tag ('en'), #subtag ('us'), or #language_tag ('en-us')
    headers = {
      'Content-Type' => matched_media_type ? matched_media_type.media_range : '',
      'Content-Encoding' => matched_encoding ? matched_encoding.encoding : '',
      'Content-Language' => matched_language ? matched_language.language_tag : '',
    }

    [200, headers, ["Hello World!"]]
  end
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/accept_headers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
