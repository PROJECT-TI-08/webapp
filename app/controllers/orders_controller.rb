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
    url = Rails.configuration.oc_api_url + "crear"
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
    url = Rails.configuration.oc_api_url + "recepcionar/" + oc_number
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
    url = Rails.configuration.oc_api_url + "rechazar/" + oc_number
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
    url = Rails.configuration.oc_api_url + "anular/" + oc_number
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
  	sftp = Net::SFTP.start(Rails.application.config.sftp_url,
    Rails.application.config.sftp_url_user, :password => 
    Rails.application.config.sftp_url_pass)
    #hydra = Typhoeus::Hydra.new
    #result = Array.new  
    all_orders = OrderFtp.all
    oc_url_api = Rails.application.config.oc_api_url
    entries = sftp.dir.entries("/pedidos/").map { |entry|
        # Descartamos dos lineas del directorio que no son archivos xml
        if entry.name != '.' && entry.name != '..'
          if all_orders.where('file_name = ?', entry.name).blank?
            OrderFtp.create!({:file_name => entry.name, :status => 0})
          end
        end    
    }
    #hydra.run
    #respond_with result, json: result
  end

  def process_order
      sftp = Net::SFTP.start(Rails.application.config.sftp_url,
      Rails.application.config.sftp_url_user, :password => 
      Rails.application.config.sftp_url_pass)
      orders_saved = OrderFtp.where('status = ?',0).first
      file = sftp.file.open("/pedidos/"+ orders_saved[:file_name], "r")
      oc_order_xml = Nokogiri::XML(file)
      oc_number    = oc_order_xml.at_css('order id').inner_text
      #Solicitamos a la api la información de la oc
      request  = request_oc(oc_number)
      response = request.run
      if response.success?                 
        data_order  = ActiveSupport::JSON.decode(response.body)[0]
        total = ApiController.new.consultar_stock(data_order['sku'])
          #data.product_stores.map(&:qty).sum
        if(data_order['cantidad'] < total)    
          ###############
          #Procesar orden
          ###############

          #get_order_oc -> api externa
          #validar stock
          #rechazar o recepcionar oc
          #emitir factura
          #despachar_stock  

          orders_saved[:order_id] = data_order['_id']
          orders_saved[:status] = 1  
        else
          orders_saved[:status] = 2
        end          
      else
          orders_saved[:status] = 2
      end
      orders_saved.save
  end

  private

  def request_oc(oc_number)
    url = Rails.configuration.oc_api_url + "obtener/" + oc_number
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
    return request
  end

end
