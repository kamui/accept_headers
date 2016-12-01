## HEAD

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
