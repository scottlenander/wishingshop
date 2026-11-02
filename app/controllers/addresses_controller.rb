# "My addresses": the signed-in user's billing address and saved shipping
# addresses. Scoped to the current user, so anyone else's is a 404.
class AddressesController < ApplicationController
  before_action :set_address, only: %i[ edit update destroy ]

  def index
    @billing = Current.user.billing_address
    @shipping = Current.user.shipping_addresses
  end

  def new
    kind = params[:kind] == "billing" ? :billing : :shipping
    return redirect_to edit_address_path(Current.user.billing_address) if kind == :billing && Current.user.billing_address

    @address = Current.user.addresses.new(kind: kind, name: Current.user.full_name)
  end

  def create
    @address = Current.user.addresses.new(address_params.merge(kind: params.dig(:address, :kind)))
    if @address.save
      redirect_to addresses_path, notice: "#{label(@address)} saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path, notice: "#{label(@address)} updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @address.destroy
    redirect_to addresses_path, notice: "#{label(@address)} deleted."
  end

  private
    def set_address
      @address = Current.user.addresses.find(params[:id])
    end

    # `kind` is only set on create, so an address can't switch between billing and shipping.
    def address_params
      params.expect(address: [ :nickname, *Address::FIELDS ])
    end

    def label(address)
      address.billing? ? "Billing address" : "Shipping address \"#{address.nickname}\""
    end
end
