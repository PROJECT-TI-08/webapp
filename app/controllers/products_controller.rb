class ProductsController < ApplicationController
  
def index
   result = Array.new
   api = ApiController.new
   Product.all.each do |item|
		sku_stock = api.consultar_stock(item[:sku])
		result.push({:sku => item[:sku],:name => item[:nombre], :qty => sku_stock})
   end
	respond_with result	
end

  def show
    respond_with Product.find(params[:id])
  end 

end