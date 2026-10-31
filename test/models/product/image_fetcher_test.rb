require "test_helper"

class Product::Import::ImageFetcherTest < ActiveSupport::TestCase
  test "only http and https URLs are allowed" do
    assert Product::Import::ImageFetcher.web_url?("https://example.com/a.png")
    assert_not Product::Import::ImageFetcher.web_url?("ftp://example.com/a.png")
    assert_not Product::Import::ImageFetcher.web_url?("file:///etc/passwd")
    assert_not Product::Import::ImageFetcher.web_url?("not a url")
  end

  test "refuses local and private network addresses" do
    fetcher = Product::Import::ImageFetcher.new
    [ "http://127.0.0.1/a.png", "http://localhost/a.png", "http://10.0.0.5/a.png", "http://192.168.1.1/a.png" ].each do |url|
      error = assert_raises(Product::Import::ImageFetcher::Error) { fetcher.fetch(url) }
      assert_match "private network", error.message
    end
  end
end
