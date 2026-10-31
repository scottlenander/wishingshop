require "csv"

# Bulk create/update of products from a CSV. Used by the admin import page and
# the products:import rake task.
#
#   sku,name,description,inventory_count,image_url
#   HOODIE,,,25,
#   WINTER-COAT,Winter Coat,Warm wool coat.,40,https://example.com/coat.png
#
# Rows are matched by SKU: known SKUs update that product, new SKUs create one.
# For existing products a blank cell keeps the current value, and
# inventory_count sets the stock (it isn't added to it).
#
#   import = Product::Import.new(csv_text)
#   import.rows      # preview: action, changes and errors per row
#   import.valid?    # no errors anywhere
#   import.apply!    # save everything in one transaction; false on failure
class Product::Import
  HEADERS = %w[ sku name description inventory_count image_url ].freeze
  MAX_BYTES = 1.megabyte
  MAX_ROWS = 1_000

  Row = Struct.new(:line, :sku, :product, :action, :changes, :errors, :description, :image_url, keyword_init: true) do
    def error? = errors.any?
  end

  attr_reader :rows, :errors

  def initialize(csv_text, image_fetcher: ImageFetcher.new)
    @image_fetcher = image_fetcher
    @errors = []
    @rows = []
    parse(csv_text.to_s)
  end

  def valid?
    errors.empty? && rows.none?(&:error?)
  end

  def summary
    counts = rows.reject(&:error?).group_by(&:action).transform_values(&:size)
    {
      created: counts.fetch(:create, 0),
      updated: counts.fetch(:update, 0),
      unchanged: counts.fetch(:unchanged, 0),
      failed: rows.count(&:error?)
    }
  end

  # Saves every row in one transaction, so one failure saves nothing.
  # Each product is saved normally (not with upsert_all), so validations and
  # the back-in-stock email callback still run. Emails go out only after the
  # whole import commits.
  def apply!
    return false unless valid?

    images = fetch_images
    return false unless valid?

    Product.transaction do
      rows.each do |row|
        next if row.action == :unchanged

        row.product.description = row.description unless row.description.nil?
        row.product.featured_image = images[row.line] if images[row.line]

        unless row.product.save
          row.errors.concat(row.product.errors.full_messages)
          raise ActiveRecord::Rollback
        end
      end
    end

    valid?
  end

  private
    def parse(text)
      text = text.dup.force_encoding(Encoding::UTF_8).delete_prefix("﻿")
      return errors << "The file is larger than 1 MB." if text.bytesize > MAX_BYTES
      return errors << "The file isn't valid UTF-8 text. Save it as CSV (UTF-8)." unless text.valid_encoding?
      return errors << "The file is empty." if text.strip.empty?

      table = CSV.parse(text, headers: true, header_converters: ->(h) { h.to_s.strip.downcase })
      return unless valid_headers?(table.headers)

      data_rows = table.each.with_index(2).reject { |row, _| row.fields.all?(&:blank?) }
      return errors << "The file has more than #{MAX_ROWS} rows. Split it into smaller files." if data_rows.size > MAX_ROWS
      return errors << "The file has no product rows." if data_rows.empty?

      existing = Product.with_rich_text_description.where(sku: skus_in(data_rows)).index_by(&:sku)
      seen = {}
      @rows = data_rows.map { |csv_row, line| build_row(csv_row, line, existing, seen) }
    rescue CSV::MalformedCSVError => e
      errors << "The file couldn't be read as CSV: #{e.message}"
    end

    def valid_headers?(headers)
      unknown = headers.compact - HEADERS
      errors << "Unknown column#{"s" if unknown.many?}: #{unknown.join(", ")}. Allowed: #{HEADERS.join(", ")}." if unknown.any?
      errors << "Missing the sku column." unless headers.include?("sku")
      errors << "Each column can only appear once." if headers.compact.uniq.size != headers.compact.size
      errors.empty?
    end

    def skus_in(data_rows)
      data_rows.filter_map { |csv_row, _| normalize_sku(csv_row["sku"]) }
    end

    def normalize_sku(value)
      value.to_s.strip.upcase.presence
    end

    def build_row(csv_row, line, existing, seen)
      sku = normalize_sku(csv_row["sku"])
      row = Row.new(line: line, sku: sku, changes: [], errors: [])

      if sku.nil?
        row.errors << "SKU is required."
        return row
      end

      if seen[sku]
        row.errors << "SKU #{sku} is also on line #{seen[sku]}."
        return row
      end
      seen[sku] = line

      product = existing[sku] || Product.new(sku: sku)
      row.product = product
      assign_fields(row, csv_row)

      if product.new_record?
        row.action = :create
        row.errors << "Name is required for new products." if product.name.blank?
      else
        row.action = row.changes.any? ? :update : :unchanged
      end

      row.errors.concat(product.errors.full_messages) if row.errors.none? && product.invalid?
      row
    end

    def assign_fields(row, csv_row)
      product = row.product
      values = csv_row.to_h.transform_values { |v| v.to_s.strip.presence }

      if (name = values["name"]) && name != product.name
        row.changes << change_text("Name", product.name, name)
        product.name = name
      end

      if (description = values["description"])
        current = product.description&.to_plain_text.to_s.strip
        if description != current
          row.changes << (product.new_record? ? "Description added" : "Description updated")
          row.description = description
        end
      end

      if (stock = values["inventory_count"])
        if stock.match?(/\A\d+\z/)
          stock = stock.to_i
          if stock != product.inventory_count || product.new_record?
            row.changes << change_text("Stock", (product.inventory_count unless product.new_record?), stock)
            product.inventory_count = stock
          end
        else
          row.errors << "Stock must be a whole number of 0 or more (got #{stock.inspect})."
        end
      elsif product.new_record?
        product.inventory_count = 0
      end

      if (url = values["image_url"])
        if ImageFetcher.web_url?(url)
          row.image_url = url
          row.changes << (product.featured_image.attached? ? "Image replaced" : "Image added")
        else
          row.errors << "Image URL must start with http:// or https://."
        end
      end
    end

    def change_text(label, from, to)
      from.nil? ? "#{label}: #{to}" : "#{label}: #{from} → #{to}"
    end

    # Downloads images before the transaction, so a slow or broken URL doesn't
    # hold the database open. A failed download becomes an error on its row.
    # Returns { line number => attachable }.
    def fetch_images
      rows.select(&:image_url).each_with_object({}) do |row, images|
        images[row.line] = @image_fetcher.fetch(row.image_url)
      rescue ImageFetcher::Error => e
        row.errors << e.message
      end
    end
end
