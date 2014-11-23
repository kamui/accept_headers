require "accept_headers"

module AcceptHeaders
  class Middleware
    def initialize(app)
      @app = app
      yield self if block_given?
    end

    def call(env)
      env["accept_headers.media_types"] = MediaType::Negotiator.new(env["HTTP_ACCEPT"])
      env["accept_headers.encodings"] = Encoding::Negotiator.new(env["HTTP_ACCEPT_ENCODING"])
      env["accept_headers.languages"] = Language::Negotiator.new(env["HTTP_ACCEPT_LANGUAGE"])

      @app.call(env)
    end
  end
end
