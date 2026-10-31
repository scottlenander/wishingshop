require "csv"

# Bulk product import: upload a CSV, review the preview, then apply it.
# The uploaded file is kept in Active Storage between preview and apply, and
# the Apply button carries its signed id (valid for 1 hour).
class Admin::ProductImportsController < Admin::BaseController
  def new
  end

  def create
    file = params[:file]
    unless file.respond_to?(:read)
      return redirect_to new_admin_product_import_path, alert: "Choose a CSV file to import."
    end
    if file.size > Product::Import::MAX_BYTES
      return redirect_to new_admin_product_import_path, alert: "The file is larger than 1 MB."
    end

    @blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename, content_type: "text/csv")
    @import = Product::Import.new(@blob.download)

    if @import.valid?
      render :create
    else
      @blob.purge
      @blob = nil
      render :create, status: :unprocessable_entity
    end
  end

  def apply
    blob = ActiveStorage::Blob.find_signed(params[:signed_id])
    unless blob
      return redirect_to new_admin_product_import_path, alert: "That preview has expired. Upload the file again."
    end

    @import = Product::Import.new(blob.download)
    if @import.apply!
      blob.purge
      s = @import.summary
      redirect_to products_path, notice: "Import complete: #{s[:created]} created, #{s[:updated]} updated, #{s[:unchanged]} unchanged."
    else
      blob.purge
      render :create, status: :unprocessable_entity
    end
  end

  def template
    send_data Product::Import::HEADERS.to_csv, filename: "products-template.csv", type: "text/csv"
  end

  def export
    csv = CSV.generate do |rows|
      rows << Product::Import::HEADERS
      Product.with_rich_text_description.order(:name).each do |product|
        rows << [ product.sku, product.name, product.description&.to_plain_text.presence, product.inventory_count, nil ]
      end
    end
    send_data csv, filename: "products-#{Date.current}.csv", type: "text/csv"
  end
end
