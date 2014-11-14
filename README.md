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

`AcceptHeaders` can parse the Accept Header and return an array of `MediaType`s in descending order according to the spec, which takes into account `q` value, `type`/`subtype` and `params` specificity.

```ruby
AcceptHeaders::MediaType.parse("text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5")
```

Will generate this equivalent array:

```ruby
[
  MediaType.new('text', 'html', params: { 'level' => '1' }),
  MediaType.new('text', 'html', q: 0.7),
  MediaType.new('*', '*', q: 0.5),
  MediaType.new('text', 'html', q: 0.4, params: { 'level' => '2' }),
  MediaType.new('text', '*', q: 0.3)
]
```

Parsing `Charset`:

```ruby
AcceptHeaders::Charset.parse("us-ascii; q=0.5, iso-8859-1, utf-8; q=0.8, macintosh")
```

generates:

```ruby
[
  Charset.new('iso-8859-1'),
  Charset.new('macintosh'),
  Charset.new('utf-8', q: 0.8),
  Charset.new('us-ascii', q: 0.5)
]
```

Parsing `Encoding`:

```ruby
AcceptHeaders::Encoding.parse("deflate; q=0.5, gzip, compress; q=0.8, identity")
```

generates:

```ruby
[
  Encoding.new('gzip'),
  Encoding.new('identity'),
  Encoding.new('compress', q: 0.8),
  Encoding.new('deflate', q: 0.5)
]
```

Parsing `Language`:

```ruby
AcceptHeaders::Language.parse("en-*, en-us, *;q=0.8")
```

generates:

```ruby
[
  Language.new('en', 'us'),
  Language.new('en', '*'),
  Language.new('*', '*', q: 0.8)
]
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/accept_headers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
