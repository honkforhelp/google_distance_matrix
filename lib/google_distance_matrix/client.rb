# frozen_string_literal: true

module GoogleDistanceMatrix
  # HTTP client making request to Google's API
  class Client
    CLIENT_ERRORS = %w[
      INVALID_REQUEST
      MAX_ELEMENTS_EXCEEDED
      OVER_QUERY_LIMIT
      REQUEST_DENIED
      UNKNOWN_ERROR
    ].freeze

    # Make a GET request to given URL
    #
    # @param url              The URL to Google's API we'll make a request to
    # @param instrumentation  A hash with instrumentation payload
    # @param options          Other options we don't care about, for example we'll capture
    #                         `configuration` option which we are not using, but the ClientCache
    #                         is using.
    #
    # @return Hash with data from parsed response body
    def get(url, instrumentation: {}, configuration: nil)
      uri = URI.parse url

      response = ActiveSupport::Notifications.instrument(
        'client_request_matrix_data.google_distance_matrix', instrumentation
      ) do
        # This is borrowed from HTTP.get_response
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http_open_timeout = configuration&.http_open_timeout.to_i
        http.open_timeout = http_open_timeout if http_open_timeout > 0

        http_read_timeout = configuration&.http_read_timeout.to_i
        http.read_timeout = http_read_timeout if http_read_timeout > 0

        http_ssl_timeout = configuration&.http_ssl_timeout.to_i
        http.ssl_timeout = http_ssl_timeout if http_ssl_timeout > 0

        http.max_retries = 0

        http.start { http.request_get(uri) }
      end

      handle response, url
    rescue Timeout::Error => error
      raise ServerError, error
    end

    private

    def handle(response, url) # rubocop:disable Metrics/MethodLength
      case response
      when Net::HTTPSuccess
        inspect_for_client_errors! response
      when Net::HTTPRequestURITooLong
        raise MatrixUrlTooLong.new url, UrlBuilder::MAX_URL_SIZE, response
      when Net::HTTPClientError
        raise ClientError, response
      when Net::HTTPServerError
        raise ServerError, response
      else # Handle this as a request error for now. Maybe fine tune this more later.
        raise ServerError, response
      end
    end

    def inspect_for_client_errors!(response)
      status = JSON.parse(response.body).fetch 'status'

      raise ClientError.new response, status if CLIENT_ERRORS.include? status

      response
    end
  end
end
