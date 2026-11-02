# Admin picks for the homepage featured product. Picks can't overlap; when none
# is active the homepage shows a random product that changes daily.
class Admin::FeaturedProductsController < Admin::BaseController
  before_action :set_featured_product, only: %i[ edit update destroy ]

  def index
    now = Time.current
    @current = FeaturedProduct.active_at(now).includes(:product).first
    @random_today = FeaturedProduct.random_for(now.to_date) unless @current
    @upcoming = FeaturedProduct.upcoming(now).includes(:product, :user)
    @past = FeaturedProduct.past(now).includes(:product, :user).limit(20)
  end

  def new
    @featured_product = FeaturedProduct.new(product_id: params[:product_id], starts_at: Time.current.change(sec: 0),
                                            ends_at: 7.days.from_now.change(sec: 0))
  end

  def create
    @featured_product = FeaturedProduct.new(featured_product_params.merge(user: Current.user))
    if @featured_product.save
      redirect_to admin_featured_products_path, notice: "#{@featured_product.product.name} will be featured."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @featured_product.update(featured_product_params)
      redirect_to admin_featured_products_path, notice: "Featured pick updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @featured_product.destroy
    redirect_to admin_featured_products_path, notice: "Featured pick removed."
  end

  private
    def set_featured_product
      @featured_product = FeaturedProduct.find(params[:id])
    end

    def featured_product_params
      params.expect(featured_product: [ :product_id, :starts_at, :ends_at ])
    end
end
