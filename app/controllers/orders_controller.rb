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
    all_orders = OrderFtp.all
    entries = sftp.dir.entries("/pedidos/").map { |entry|
        # Descartamos dos lineas del directorio que no son archivos xml
        if entry.name != '.' && entry.name != '..'
          if all_orders.where('file_name = ?', entry.name).blank?
            OrderFtp.create!({:file_name => entry.name, :status => 0})
          end
        end    
    }
  end

  def process_order_second_time
    process_order(2)
  end

  def process_order_first_time1
    process_order(0)
  end

  def process_order(status)
      sftp = Net::SFTP.start(Rails.application.config.sftp_url,
      Rails.application.config.sftp_url_user, :password => 
      Rails.application.config.sftp_url_pass)
      orders_saved = OrderFtp.where('status = ?',status).first
      file = sftp.file.open("/pedidos/"+ orders_saved[:file_name], "r")
      oc_order_xml = Nokogiri::XML(file)
      #logger.debug('xml: '+oc_order_xml)
      oc_number    = oc_order_xml.at_css('order id').inner_text
      #Solicitamos a la api la información de la oc
      #logger.debug('xml: '+oc_order_xml)
      cantidad = nil
      request  = request_oc(oc_number)
      response = request.run
      orders_saved[:status] = 2
      if response.success?                 
        oc_order  = ActiveSupport::JSON.decode(response.body)[0]
        product   = Product.where('sku = ?',oc_order['sku']).first
        oc_precio    = product['precio_unitario'] 
        cantidad   = oc_order['cantidad']
        total = ApiController.new.consultar_stock(oc_order['sku'])
        logger.debug('Cantidad')
        logger.debug(cantidad)
        logger.debug('Total')
        logger.debug(total)
        if(cantidad < total)    
            request_recep = OrdersController.new.recepcionar_oc(oc_number)
            if request_recep[:status] 
              order_obj = Order.create!({
              :_id                => oc_order['_id'], 
              :canal              => oc_order['canal'],
              :proveedor          => oc_order['proveedor'], 
              :cliente            => oc_order['cliente'],
              :sku                => oc_order['sku'], 
              :cantidad           => oc_order['cantidad'], 
              :cantidadDespachada => oc_order['cantidadDespachada'],
              :precio_unitario    => oc_order['precioUnitario'], 
              :fechaEntrega       => oc_order['fechaEntrega'],
              :fechaDespachos     => oc_order['fechaDespachos'], 
              :estado             => oc_order['estado']})
              request_inv = InvoicesController.new.emitir_factura(oc_number)
              if request_inv[:status]
                result = request_inv[:result]
                order_obj.factura = Factura.create!({
                :_id   => result['_id'], 
                :bruto => result['bruto'],
                :iva   => result['iva'], 
                :total => result['total'] })
                order_obj.save
                stock_aux = StoresController.new
                almacen_despacho =  Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,true,false).first
                   j = 0
                   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
                      list_products = stock_aux.get_stock(oc_order['sku'],fabrica['_id'])
                      if list_products[:status]
                        #new_list = list_products[:result].select{|aux| aux['despachado'] == false}
                        list_products[:result].each do |item|
                          if j < cantidad
                            request_mov = stock_aux.mover_stock(item['_id'],almacen_despacho['_id'])
                            response_mov = request_mov.run
                            if response_mov.success?    
                                result_mov_prod = JSON.parse(response_mov.body)     
                                logger.debug(oc_number)
                                logger.debug(oc_precio)
                                logger.debug(result_mov_prod['_id'])                   
                                #despachar_stock
                                request_despacho = stock_aux.despachar_stock(result_mov_prod['_id'],'n.a',oc_precio.to_i,oc_number)
                                response_despacho = request_despacho.run
                         
                                logger.debug('despachar_stock_error2: '+response_despacho.body)
                                if response_despacho.success?

                                end 
                            end
                          else
                            break
                          end
                          j = j + 1
                        end
                      end
                   end

                orders_saved[:status] = 1     
              end  
            end       
        end
      else
        logger.debug('falló')
      end 
      orders_saved[:order_id] = oc_number
      orders_saved.save
  end

  private

  def request_oc(oc_number)
    logger.debug('Inicia request_oc')
    url = Rails.configuration.oc_api_url + "obtener/" + oc_number.to_s
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
    logger.debug('Termina request_oc')
    return request
  end

end
