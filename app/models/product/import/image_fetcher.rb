require "ipaddr"
require "net/http"
require "resolv"

# Downloads a product image for Product::Import.
#
# Limits, to keep imports safe and quick:
# - http/https only, with up to 3 redirects
# - 10 second timeouts and a 5 MB size cap
# - the response must be an image
# - no private or local network addresses (stops the server being used to
#   reach internal services)
class Product::Import::ImageFetcher
  class Error < StandardError; end

  MAX_BYTES = 5.megabytes
  MAX_REDIRECTS = 3
  TIMEOUT = 10

  def self.web_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  # Returns { io:, filename:, content_type: }, ready to attach.
  def fetch(url, redirects_left = MAX_REDIRECTS)
    uri = URI.parse(url)
    raise Error, "Image URL must start with http:// or https://." unless self.class.web_url?(url)
    raise Error, "Image URL #{uri.host} points to a private network address." if private_host?(uri.host)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.request(Net::HTTP::Get.new(uri)) do |response|
        case response
        when Net::HTTPRedirection
          raise Error, "Image URL redirects too many times." if redirects_left.zero?
          return fetch(URI.join(uri, response["location"]).to_s, redirects_left - 1)
        when Net::HTTPSuccess
          return read_image(response, uri)
        else
          raise Error, "Couldn't download image (HTTP #{response.code}) from #{url}."
        end
      end
    end
  rescue Error
    raise
  rescue StandardError => e
    raise Error, "Couldn't download image from #{url}: #{e.message}"
  end

  private
    def read_image(response, uri)
      content_type = response.content_type.to_s
      raise Error, "#{uri} isn't an image (#{content_type.presence || "unknown type"})." unless content_type.start_with?("image/")

      body = +""
      response.read_body do |chunk|
        body << chunk
        raise Error, "Image at #{uri} is larger than 5 MB." if body.bytesize > MAX_BYTES
      end

      filename = File.basename(uri.path).presence || "image"
      { io: StringIO.new(body), filename: filename, content_type: content_type }
    end

    def private_host?(host)
      addresses = Resolv.getaddresses(host)
      raise Error, "Couldn't find the image host #{host}." if addresses.empty?

      addresses.any? do |address|
        ip = IPAddr.new(address)
        ip.loopback? || ip.private? || ip.link_local? || ip.to_s == "0.0.0.0"
      end
    end
end
