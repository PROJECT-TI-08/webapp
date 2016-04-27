require 'net/sftp'

class OrdersController < ApplicationController
   before_filter :authenticate_user!
  def index
    respond_with Order.all
  end
  def show
    respond_with Order.find(params[:id])
  end 
  def getOrdersByFTP
	sftp = Net::SFTP.start('mare.ing.puc.cl','integra8', :password => 'UADkEXqZ')
	sftp.file.open("/pedidos", "r") do |f|
	  while !f.eof?
	    puts f.gets
	  end
	end
	respond_with true
  end
end
