# Admins list, add, edit (including moving to another product) and remove
# back-in-stock subscribers.
class Admin::SubscribersController < Admin::BaseController
  before_action :set_subscriber, only: %i[ edit update destroy ]

  def index
    @subscribers_by_product = Subscriber.includes(:product)
                                        .order(:email)
                                        .group_by(&:product)
                                        .sort_by { |product, _| product.name }
  end

  def new
    @subscriber = Subscriber.new(product_id: params[:product_id])
  end

  def create
    @subscriber = Subscriber.new(subscriber_params)
    if @subscriber.save
      redirect_to admin_subscribers_path, notice: "Subscriber added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @subscriber.update(subscriber_params)
      redirect_to admin_subscribers_path, notice: "Subscriber updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @subscriber.destroy
    redirect_to admin_subscribers_path, notice: "Subscriber removed."
  end

  private
    def set_subscriber
      @subscriber = Subscriber.find(params[:id])
    end

    def subscriber_params
      params.expect(subscriber: [ :email, :product_id ])
    end
end
