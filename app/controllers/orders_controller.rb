require 'net/sftp'
require 'typhoeus'
require 'nokogiri'

class OrdersController < ApplicationController
   #before_filter :authenticate_user!

  def index
    respond_with Order.all
  end
  def show
    respond_with Order.find(params[:id])
  end 

  def run_oc
      logger.debug("Cron test #{Time.now}")
  end

  #:canal, :cantidad, :sku, :proveedor, :precio, :notas
  def crear_oc(oc_order)    
    url = Rails.configuration.oc_api_url_dev+"crear"
    request = Typhoeus::Request.new(
    url, 
    method: :put,
    body: oc_order,
    headers: {'Content-Type'=> "application/x-www-form-urlencoded"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false}
    end
  end

  def recepcionar_oc(oc_number)
    url = Rails.configuration.oc_api_url_dev + "recepcionar/" + oc_number
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result =>  JSON.parse(response.body)}
    end
  end

  def rechazar_oc(oc_number, rechazo)
    url = Rails.configuration.oc_api_url_dev + "rechazar/" + oc_number
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    body: {
      rechazo: rechazo
    },
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false}
    end
  end

  def anular_oc(oc_number, motivo)
    url = Rails.configuration.oc_api_url_dev + "rechazar/" + oc_number
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    body: {
      motivo: motivo
    },
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result => JSON.parse(response.body)}               
    else
       return {:status => false}
    end
  end

  def obtener_oc(oc_number)
    request = request_oc(oc_number)
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false}
    end
    #respond_with response.response_body, json: response.response_body
  end  

  def get_orders_by_ftp
  	sftp = Net::SFTP.start(Rails.application.config.sftp_url_dev,
    Rails.application.config.sftp_url_dev_user, :password => 
    Rails.application.config.sftp_url_dev_pass)
    hydra = Typhoeus::Hydra.new
    result = Array.new  
    all_orders = OrderFtp.all
    oc_url_api = Rails.application.config.oc_api_url_dev
    entries = sftp.dir.entries("/pedidos/").map { |entry|
        # Descartamos dos lineas del directorio que no son archivos xml
        if entry.name != '.' && entry.name != '..'
          if all_orders.where(:file_name => entry.name).blank?
              file = sftp.file.open("/pedidos/"+ entry.name, "r")
              oc_order = Nokogiri::XML(file)
              oc_number    = oc_order.at_css('order id').inner_text
              #Solicitamos a la api la información de la oc
              request = request_oc(oc_number)
              request.on_complete do |response|
                order_ftp = Hash.new
                if response.success?                 
                    data = ActiveSupport::JSON.decode(response.body)[0]
                    result.push(data)

                    ###############
                    #Procesar orden
                    ###############  
                    
                    order_ftp['status'] = 1     
                  else
                      order_ftp['status'] = 2
                  end

                  order_ftp['order_id']  = oc_number
                  order_ftp['file_name'] = entry.name
                  OrderFtp.create!(order_ftp)
              
              end
              hydra.queue(request)
          end
        end    
    }
    hydra.run
    respond_with result, json: result
  end

  private

  def request_oc(oc_number)
    url = Rails.configuration.oc_api_url_dev + "obtener/" + oc_number
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
    return request
  end

end
