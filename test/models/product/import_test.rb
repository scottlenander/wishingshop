require "test_helper"

class Product::ImportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  HEADER = "sku,name,description,inventory_count,image_url\n"

  # Stands in for real downloads.
  class FakeFetcher
    attr_reader :urls

    def initialize(fail_for: nil)
      @fail_for = fail_for
      @urls = []
    end

    def fetch(url)
      @urls << url
      raise Product::Import::ImageFetcher::Error, "Couldn't download image from #{url}." if url == @fail_for

      { io: StringIO.new(Rails.root.join("test/fixtures/files/pixel.png").binread), filename: "pixel.png", content_type: "image/png" }
    end
  end

  def import(rows, **options)
    Product::Import.new(HEADER + rows, **options)
  end

  test "creates new products and updates known SKUs" do
    result = import("t-shirt,,,40,\nWINTER-COAT,Winter Coat,Warm wool.,7,\n")

    assert result.valid?
    assert_equal({ created: 1, updated: 1, unchanged: 0, failed: 0 }, result.summary)
    assert_difference("Product.count", 1) { assert result.apply! }

    assert_equal 40, products(:tshirt).reload.inventory_count
    coat = Product.find_by!(sku: "WINTER-COAT")
    assert_equal "Winter Coat", coat.name
    assert_equal 7, coat.inventory_count
    assert_equal "Warm wool.", coat.description.to_plain_text
  end

  test "blank cells keep existing values and stock is set, not added" do
    products(:tshirt).update!(description: "Soft cotton.")

    assert import("T-SHIRT,,,5,\n").apply!

    tshirt = products(:tshirt).reload
    assert_equal "T-Shirt", tshirt.name
    assert_equal "Soft cotton.", tshirt.description.to_plain_text
    assert_equal 5, tshirt.inventory_count
  end

  test "rows with nothing to change are unchanged" do
    result = import("T-SHIRT,T-Shirt,,15,\n")
    assert_equal :unchanged, result.rows.first.action
  end

  test "importing the same file twice gives the same result" do
    import("T-SHIRT,,,9,\n").apply!
    result = import("T-SHIRT,,,9,\n")
    assert_equal :unchanged, result.rows.first.action
  end

  test "reports file errors" do
    assert_includes Product::Import.new("").errors, "The file is empty."
    assert_match "Unknown column: colour", Product::Import.new("sku,colour\nA,b\n").errors.first
    assert_includes Product::Import.new("name\nHat\n").errors, "Missing the sku column."
    assert_match "couldn't be read as CSV", Product::Import.new("sku,name\n\"A,b\n").errors.first
  end

  test "reports row errors with line numbers" do
    result = import(",No SKU,,1,\nHAT,,,1,\nCAP,Cap,,lots,\nSOCK,Sock,,1,ftp://x\nSOCK,Sock,,2,\n")

    errors = result.rows.to_h { |row| [ row.line, row.errors.join(" ") ] }
    assert_equal "SKU is required.", errors[2]
    assert_equal "Name is required for new products.", errors[3]
    assert_match "Stock must be a whole number", errors[4]
    assert_match "Image URL must start with http", errors[5]
    assert_equal "SKU SOCK is also on line 5.", errors[6]
    assert_not result.valid?
  end

  test "an invalid SKU is reported" do
    assert_match "Sku can only contain", import("BAD SKU!,Hat,,1,\n").rows.first.errors.join
  end

  test "an invalid file saves nothing" do
    result = import("T-SHIRT,,,99,\nNEW,,,1,\n")

    assert_no_difference("Product.count") { assert_not result.apply! }
    assert_equal 15, products(:tshirt).reload.inventory_count
  end

  test "a failed save rolls back the whole import" do
    Product.create!(name: "Taken", sku: "TAKEN")
    result = import("T-SHIRT,,,99,\nNEW-ONE,Taken,,1,\n")
    # Make the second row fail on save, after the first has been saved.
    result.rows.last.product.define_singleton_method(:save) { errors.add(:base, "Boom"); false }

    assert_not result.apply!
    assert_equal 15, products(:tshirt).reload.inventory_count
    assert_nil Product.find_by(sku: "NEW-ONE")
  end

  test "restocking from 0 sends the back-in-stock emails" do
    assert_emails 1 do
      assert import("HOODIE,,,10,\n").apply!
    end
  end

  test "an image URL downloads and attaches the image" do
    fetcher = FakeFetcher.new
    result = import("T-SHIRT,,,,https://example.com/pixel.png\n", image_fetcher: fetcher)

    assert_equal [ "Image added" ], result.rows.first.changes
    assert result.apply!
    assert_equal [ "https://example.com/pixel.png" ], fetcher.urls
    assert products(:tshirt).reload.featured_image.attached?
  end

  test "a failed image download saves nothing" do
    fetcher = FakeFetcher.new(fail_for: "https://example.com/missing.png")
    result = import("T-SHIRT,,,1,\nCAP,Cap,,1,https://example.com/missing.png\n", image_fetcher: fetcher)

    assert_not result.apply!
    assert_match "Couldn't download image", result.rows.last.errors.join
    assert_equal 15, products(:tshirt).reload.inventory_count
  end
end
