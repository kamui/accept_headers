## HEAD / Unreleased

  * Validate every supported offer before negotiation and raise `AcceptHeaders::InvalidSupportedValue` for invalid application configuration. Supported offers must be concrete values without quality weights; request parsing remains lenient.
  * Add `MediaType#content_type` to serialize response media types with their parameters and without quality weights.
  * Preserve HTTP parameter bytes through parsing, matching, and response escaping, including ASCII-compatible multibyte headers and supported strings. A backslash byte introduces a quoted pair even within a Ruby multibyte character; this corrects 0.2.0's character-based parsing.
  * Match identical media parameter bytes across Ruby encoding labels without transcoding. UTF-8, ASCII-8BIT, and ISO-8859-1 strings with the same bytes now match where 0.2.0 could return `nil`; different bytes remain distinct.
  * Match `charset` parameter values with ASCII-only case folding, without the Unicode case folding used in 0.2.0.
  * Document the unreleased validation contract and use parameter-preserving response headers in the Rack example.

## 0.2.0 / October 20, 2026

  * Replace Travis CI with GitHub Actions covering maintained Ruby 3.3, 3.4, and 4.0, and repair fresh test dependency setup.
  * Follow RFC 9110 negotiation rules and RFC 4647 Basic Filtering for languages.
  * Honor specific quality values and exclusions before wildcard preferences.
  * Match declared media parameters and preserve supported representation parameters instead of copying requested parameters.
  * Preserve quoted delimiters and escapes, validate media tokens, and serialize media parameters before quality values.
  * Handle raw HTTP field bytes without encoding exceptions and preserve quoted non-ASCII values.
  * Parse current quality syntax, including `0.`, `1.`, and case-insensitive `q`, while retaining the documented invalid-quality recovery value.
  * Distinguish missing and empty fields and apply encoding identity fallback and exclusion rules.
  * Support multi-subtag languages and case-insensitive matching. Replace `en-*` header ranges with `en`; bare supported tags remain bare.
  * Compare values by all their fields instead of equating unrelated values with the same sort priority.
  * Update usage, upgrade notes, and Rack 3 examples. These corrections change results for callers relying on the previous behavior; see [Upgrading from 0.1.0 to 0.2.0](README.md#upgrading-from-010-to-020) before upgrading.

## 0.1.0 / April 19, 2019

  * Require ruby 2.4 minimum.
  * Upgrade dev dependencies

## 0.0.9 / December 1, 2016

  * Require ruby 2.2 minimum.
  * Add `#to_s` method for all Negotiators
  * Return no header if parse header is nil
  * First attempt at rack middleware with simple specs.

## 0.0.8 / November 23, 2014

  * Change `#negotiate` to return the type instead of a hash. In the case of `MediaType` it'll also populate `extensions` from the matching accept header media type.

## 0.0.7 / November 19, 2014

  * Rename `MediaType` `params` to `extensions`, since params technically includes the `q` value.
  * Support rbx invalid `Float` exception message.
  * Only strip accept param keys, values can contain white space if quoted.

## 0.0.6 / November 17, 2014

  * Support parsing params with quoted values.
  * Fix bug in `#negotiate` returning nil on first q=0 match, it should skip this match and move on to the next one in the array input.
  * Fix Charset typos in README.
  * Add specs for ignoring accept header prefixes.

## 0.0.5 / November 16, 2014

  * Add `#accept?` and `#reject?` methods to all negotiators.
  * Add `#accept?` method to all negotiators.
  * Return nil if no matches on `#negotiate`.
  * Fix matching logic in `MediaType`, `Encoding`, and `Language`.
  * Test all IANA registered encodings against the parser.
  * Fix `simplecov` loading.
  * Update `audio.csv` media type file with typo fix.
  * More specs.

## 0.0.4 / November 15, 2014

  * Add MediaType#media_range which is the type/subtype as a string.
  * Add Language#language_tag which is the primary_tag/subtag as a string.
  * Test all IANA registered media types against the parser.

## 0.0.3 / November 15, 2014

  * Remove `Accept-Charset` support since it's obsolete.

## 0.0.2 / November 15, 2014

  * Add `Negotiator`s which can parse and find the best match.

## 0.0.1 / November 14, 2014

  * Initial release.
