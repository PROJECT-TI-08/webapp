class OrdersController < ApplicationController
   before_filter :authenticate_user!
  def index
    respond_with Order.all
  end
  def show
    respond_with Order.find(params[:id])
  end 
end
