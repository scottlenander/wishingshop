require "test_helper"

class ShippingMethodTest < ActiveSupport::TestCase
  test "three methods with prices" do
    assert_equal %w[ standard two_day same_day ], ShippingMethod.ids
    assert_equal 9_99, ShippingMethod.find("two_day").cost_cents(10_000)
    assert_equal 19_99, ShippingMethod.find("same_day").cost_cents(10_000)
    assert_nil ShippingMethod.find("teleport")
  end

  test "standard shipping is free from $50" do
    standard = ShippingMethod.find("standard")
    assert_equal 4_99, standard.cost_cents(49_99)
    assert_equal 0, standard.cost_cents(50_00)
  end
end
