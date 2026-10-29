# Parent for every controller under /admin. Only admins get through.
class Admin::BaseController < ApplicationController
  before_action :require_admin
end
