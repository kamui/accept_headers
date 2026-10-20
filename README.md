[![CI](https://github.com/kamui/accept_headers/actions/workflows/ci.yml/badge.svg)](https://github.com/kamui/accept_headers/actions/workflows/ci.yml)

# AcceptHeaders

AcceptHeaders parses HTTP `Accept`, `Accept-Encoding`, and `Accept-Language` headers and negotiates a match against the representations your application supports. It has no runtime dependencies.

This README describes version 0.2.0. See [Upgrading from 0.1.0 to 0.2.0](#upgrading-from-010-to-020) before updating an existing installation.

Negotiation follows [RFC 9110, sections 12.4 and 12.5](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.4). Language matching uses [RFC 4647 Basic Filtering](https://www.rfc-editor.org/rfc/rfc4647.html#section-3.3.1). `Accept-Charset` is not supported because it is deprecated.

## Installation

CI covers the maintained Ruby series: 3.3, 3.4, and 4.0. Older Ruby versions remain allowed by the gem specification but are not tested.

Add the gem to your Gemfile and run `bundle install`:

```ruby
gem 'accept_headers', '~> 0.2.0'
```

## Usage

```ruby
require 'accept_headers'
```

Each negotiator accepts a header value, with or without its conventional header name prefix. `#list` returns parsed entries sorted by preference. `#negotiate` accepts one supported string or an array and returns a `MediaType`, `Encoding`, or `Language`, or `nil` when none is acceptable. `#accept?` checks whether negotiation succeeds.

Entries in `#list` describe client preferences. Their order alone does not determine the best supported representation. Negotiation accounts for the most specific matching range before comparing quality values.

### Media types

```ruby
media_types = AcceptHeaders::MediaType::Negotiator.new(
	'text/html;q=0.1, text/*;q=0.9, application/json;q=0.5'
)

media_types.negotiate(['text/html', 'application/json']).media_range
# => "application/json"

media_types.accept?('text/html')
# => true

AcceptHeaders::MediaType::Negotiator.new('text/html;q=0, */*;q=1').accept?('text/html')
# => false
```

The exact `text/html` range sets HTML's quality to `0.1`, even though `text/*` has a higher quality. A more specific positive range can also override a wildcard exclusion.

Media parameters constrain the match. Declare each representation that your application actually supports:

```ruby
versions = AcceptHeaders::MediaType::Negotiator.new(
	'application/json;version=2, application/json;version=1;q=0.8'
)

match = versions.negotiate(['application/json;version=1', 'application/json;version=2'])
match.media_range
# => "application/json"
match.extensions
# => { "version" => "2" }

versions.negotiate('application/json')
# => nil
```

`#extensions` retains its historical name and contains media parameters. Under RFC 9110, parameters after `q` are also media parameters. Negotiation preserves the selected supported representation's parameters. It does not copy unsupported parameters from the request.

Media type names and parameter names match without regard to case. Parameter values are case-sensitive except for `charset` values. Double-quoted values support commas, semicolons, and backslash escapes. `#to_s` quotes parameter values when needed and writes `q` last.

### Encodings

```ruby
encodings = AcceptHeaders::Encoding::Negotiator.new('br, gzip;q=0.8')
encodings.negotiate(['gzip', 'identity']).encoding
# => "gzip"
encodings.accept?('identity')
# => true

AcceptHeaders::Encoding::Negotiator.new('').accept?('gzip')
# => false
AcceptHeaders::Encoding::Negotiator.new('').accept?('identity')
# => true
AcceptHeaders::Encoding::Negotiator.new(nil).accept?('gzip')
# => true
```

A missing encoding header allows any coding. A present empty header allows only an unencoded response, represented by `identity`. For a nonempty header, identity is a fallback unless `identity;q=0` or `*;q=0` excludes it. Explicit coding preferences take precedence over `*`. Coding names match without regard to case.

Selecting `gzip` does not compress the response body. Your application or compression middleware must produce the selected encoding. Omit `Content-Encoding` for identity responses.

### Languages

```ruby
languages = AcceptHeaders::Language::Negotiator.new('zh-Hant-TW, en;q=0.8')
languages.negotiate(['en-US', 'zh-Hant-TW']).language_tag
# => "zh-hant-tw"
languages.accept?('en-GB')
# => true
languages.accept?('eng')
# => false

AcceptHeaders::Language::Negotiator.new('en').negotiate('en').language_tag
# => "en"
```

Basic Filtering matches a complete range or a prefix followed by a hyphen, without regard to case. Ranges can contain multiple subtags. `*` matches otherwise unspecified languages. More specific ranges determine quality and exclusions.

Use `en` to match English variants. Extended wildcard ranges such as `en-*` are outside the HTTP basic language-range syntax and are skipped. This is filtering, so `en-GB` does not fall back to `en` or match `en-US`.

`#primary_tag` returns the first subtag. `#subtag` returns the remaining subtags as one lowercase string. For a bare tag, `#subtag` retains the historical `*` sentinel. Language tags returned by negotiation are lowercase supported tags. Bare tags remain bare, so `en` is not emitted as `en-*`.

### Missing, empty, and malformed headers

A `nil` header represents an absent field and allows any supported value. A present empty `Accept` or `Accept-Language` contains no acceptable entries. Empty `Accept-Encoding` allows only identity.

The parsers skip malformed entries. An unterminated quoted string rejects the whole list because its comma boundaries are ambiguous. Apostrophes are token characters, not string delimiters. Headers with an invalid Ruby string encoding are read as raw HTTP bytes. Quoted non-ASCII values are preserved.

Invalid quality values recover to `0.001`, preserving this library's lenient parsing policy. Missing quality defaults to `1`. Valid quality syntax follows RFC 9110: values range from `0` to `1` with at most three decimal digits, including `0.`, `1.`, and `1.000`. The parameter name `q` is case-insensitive.

`#to_s` produces a normalized preference header, including quality values. Use `#media_range`, `#encoding`, or `#language_tag` when you need the selected value alone. With `==`, objects compare equal only when their class, type-specific fields, and quality values agree. Sorting order does not imply equality.

## Rack middleware

The middleware adds negotiators to the request environment. The application selects representations and creates the response:

```ruby
require 'accept_headers/middleware'

use AcceptHeaders::Middleware
run lambda { |env|
	media = env['accept_headers.media_types'].negotiate('application/json')
	encoding = env['accept_headers.encodings'].negotiate('identity')
	language = env['accept_headers.languages'].negotiate(['en-US', 'en-GB'])
	vary = 'Accept, Accept-Encoding, Accept-Language'

	if media && encoding && language
		headers = {
			'content-type' => media.media_range,
			'content-language' => language.language_tag,
			'vary' => vary
		}
		[200, headers, ['{"message":"Hello"}']]
	else
		[406, { 'content-type' => 'text/plain', 'vary' => vary }, ['Not acceptable']]
	end
}
```

This example supports an unencoded JSON body in two English locales. It chooses to honor negotiation failures with `406`. Applications can choose a different fallback policy. When request headers influence response selection, set `Vary` so caches distinguish the variants. Rack 3 response header names must be lowercase.

## Upgrading from 0.1.0 to 0.2.0

Version 0.2.0 corrects behavior from version 0.1.0:

- Explicit exclusions and specific media preferences now take precedence over broader wildcard matches.
- Parameterized media requests require matching supported parameters. Replace `negotiate('application/json')` with the versioned representations your application actually supports.
- Media parameters follow RFC 9110, including parameters after `q`. Serialization places `q` last and quotes values when needed.
- Missing and empty headers have distinct meanings. Identity fallback follows the encoding rules above.
- Replace `en-*` header ranges with `en`. Multi-subtag language ranges now work, and bare supported tags remain bare.
- Equality compares actual values, including parameters. Two different values with equal sort priority are no longer equal.

The public negotiator classes, constructors, and `#extensions` accessor remain available. These corrections can change selection results for callers that depended on the previous behavior.

## Development

Install dependencies with `bundle install`, then run the complete suite:

```sh
bundle exec rake test
```

The suite includes negotiation regressions and parser checks against the bundled IANA media-type and coding snapshots. Those snapshots are historical fixtures, not a live registry mirror. The CI workflow runs the suite on Ruby 3.3, 3.4, and 4.0.

## Contributing

1. Fork [kamui/accept_headers](https://github.com/kamui/accept_headers).
2. Create a branch for your change.
3. Add regression tests and run the suite.
4. Open a pull request.
