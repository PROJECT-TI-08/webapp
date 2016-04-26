require 'net/ftp'

class OrdersController < ApplicationController
   before_filter :authenticate_user!
  def index
    respond_with Order.all
  end
  def show
    respond_with Order.find(params[:id])
  end 
  def getOrdersByFTP
	Net::FTP.open('ftp.merchant-e.net') do |ftp|
	  ftp.login('jdiego@merchant-e.net', '9b704fc342725f2062d59fcf3ae6ed223f10da534f63507efa70fe79cba6303d')
	  ftp.chdir('/')
	  ftp.getbinaryfile('test.csv', 'copy_test.csv')
	end
	respond_with true
  end
end
