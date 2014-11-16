## HEAD

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
