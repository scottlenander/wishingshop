require "test_helper"

class Admin::ProductImportsControllerTest < ActionDispatch::IntegrationTest
  def csv_upload(content)
    Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: "products.csv")
  end

  test "standard users are turned away" do
    sign_in_as users(:one)

    get new_admin_product_import_path
    assert_redirected_to root_path

    post admin_product_import_path, params: { file: csv_upload("sku,inventory_count\nT-SHIRT,1\n") }
    assert_redirected_to root_path
  end

  test "the upload form skips Turbo so the preview page can render" do
    sign_in_as users(:admin)

    get new_admin_product_import_path
    assert_response :success
    assert_select "form[action='#{admin_product_import_path}'][data-turbo=false]"
  end

  test "upload shows a preview without saving, then apply saves" do
    sign_in_as users(:admin)

    post admin_product_import_path, params: { file: csv_upload("sku,name,inventory_count\nT-SHIRT,,40\nCAP,Cap,3\n") }
    assert_response :success
    assert_select "tr[data-line='2'] td", text: "Update"
    assert_select "tr[data-line='3'] td", text: "Create"
    assert_equal 15, products(:tshirt).reload.inventory_count

    signed_id = css_select("form[action='#{apply_admin_product_import_path}'] input[name=signed_id]").first["value"]
    assert_difference("Product.count", 1) { post apply_admin_product_import_path, params: { signed_id: signed_id } }
    assert_redirected_to products_path
    assert_equal "Import complete: 1 created, 1 updated, 0 unchanged.", flash[:notice]
    assert_equal 40, products(:tshirt).reload.inventory_count
  end

  test "a file with errors can't be applied" do
    sign_in_as users(:admin)

    post admin_product_import_path, params: { file: csv_upload("sku,inventory_count\nT-SHIRT,lots\n") }
    assert_response :unprocessable_entity
    assert_select "tr[data-line='2'] td", text: /Stock must be a whole number/
    assert_select "input[name=signed_id]", count: 0
  end

  test "an expired or tampered preview is refused" do
    sign_in_as users(:admin)

    post apply_admin_product_import_path, params: { signed_id: "nope" }
    assert_redirected_to new_admin_product_import_path
  end

  test "upload without a file asks for one" do
    sign_in_as users(:admin)

    post admin_product_import_path
    assert_redirected_to new_admin_product_import_path
  end

  test "template and export are CSV" do
    sign_in_as users(:admin)

    get template_admin_product_import_path
    assert_equal "text/csv", response.media_type
    assert_equal "sku,name,description,inventory_count,image_url\n", response.body

    get export_admin_product_import_path
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "T-SHIRT,T-Shirt,,15,"
  end
end
