class ApiController < ApplicationController
   #before_filter :authenticate_user!

def test

order_obj = Order.create!({:_id => '342332', :canal=> 'b2b',
              :proveedor => 'sdfsdfs3242', :cliente => 'sdfsd3432',
              :sku => '18', :cantidad => 18, :cantidadDespachada => 0,
              :precioUnitario => 45345, :fechaEntrega => '2016-11-11',
              :fechaDespachos => ['2016-12-12','2015-05-02'], :estado => 'ok'})
               factura =  Factura.create!({:_id => 'sdfsdfsdf23', :bruto => 3232,
               :iva => 23423, :total => 234234})
               order_obj.factura = factura
               order_obj.save

#result = StoresController.new.mover_stock_bodega('571262b7a980ba030058a7e7','571262aaa980ba030058a31e',
#  '572ca6811b6a8c030076b422',9474.0)
#response = result.run
#logger.debug(response.body)
  #result = StoresController.new.despachar_stock('571262b7a980ba030058a7e7','a','9474','572ca6811b6a8c030076b422')
  #response = result.run
  #result = StoresController.new.get_stock('18','571262aaa980ba030058a31e')
  #'571262aaa980ba030058a3ae')
  #,'571262aaa980ba030058a31e')
 #proveedor = Rails.configuration.grupos_skus.detect{|aux| aux[:sku] == 2}
 respond_to do |format|
    format.json { render json: order_obj}
    format.html { render json: order_obj }
  end
end

###############################################
################### CLIENTE ###################
###############################################

# Metodo para notificar a un proveedor un pago
def enviar_transaccion(trx,idfactura)
  logger.debug("...Inicio enviar transaccion")
  #info = InfoGrupo.where('id_banco= ?',trx['destino']).first
  #url = 'http://integra'+info[:numero].to_s+'.ing.puc.cl/api/pagos/recibir/'+trx[0]['_id'].to_s
  url = 'http://localhost:3000/api/pagos/recibir/'+trx['_id'].to_s
  request = Typhoeus::Request.new(
    url,
    method: :get,
    params:{
      idfactura: idfactura
    },
    headers: { ContentType: "application/json"})
  response = request.run
  logger.debug("...Fin enviar transaccion")
  return {:validado => true, :trx => trx}
end

# Metodo con el cual el cliente recibe una
# factura y procede a pagarla
def validar_factura
    logger.debug("...Inicio validar factura")
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:validado] = false
    result[:idfactura] = idfactura 
    response_inv = InvoicesController.new.obtener_factura(idfactura)

    if response_inv[:status]

      result_inv = response_inv[:result]
      cliente = InfoGrupo.where('id_grupo = ?',result_inv[0]['cliente']).first
      # Una vez recibida la factura se procede a realizar el pago
      response_bank =BankController.new.transferir(result_inv[0]['total'],
        Rails.application.config.bank_account,cliente['id_banco'])
                      logger.debug(response_bank)
      if response_bank[:status]
        result_bank = response_bank[:result]
        # Se envia la transaccion para que el cliente verifique el pago
        result[:validado] = true
        Spawnling.new do
          enviar_transaccion(result_bank,idfactura)
        end
      end  
    end
    logger.debug("...Fin validar factura")
    respond_with result, json: result
end

# Metodo con el cual un proveedor notifica a un
# cliente que sus productos han sido despachados
def validar_despacho
    idfactura = params.require(:idfactura)
    result    = Hash.new 
    result[:idfactura] = idfactura 
    result[:validado]  = true
    logger.debug("...Validar despacho")
    # Una vez se ha pagado el proveedor confirma el
    # despacho de los insumos
    Spawnling.new do
      mover_productos(idfactura)
    end
    respond_with result, json: result
end

# Metodo para mover los productos del almacen de recepción
# a los almacenes centrales
def mover_productos(idfactura)
  logger.debug("...Inicio mover productos")
   response_inv = InvoicesController.new.obtener_factura(idfactura)
   factura      = nil
   oc           = nil
   sku          = nil
   cantidad     = nil
   if response_inv[:status]
     factura     = response_inv[:result]
     response_oc = OrdersController.new.obtener_oc(factura[0]['oc'])
     if response_oc[:status]
        oc       = response_oc[:result]
        sku      = oc[0]['sku']
        cantidad = oc[0]['cantidad']
     end
   end
   stock_aux = StoresController.new
   product   = Product.where('sku = ?',sku).first
   precio    = product['precio_unitario'] 
   grupo = InfoGrupo.where('id_grupo = ?',oc[0]['cliente']).first
   almacen_cliente = grupo['id_almacen']
   almacen_recepcion =  Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,true).first
   list_products = stock_aux.get_stock(sku,almacen_recepcion['_id'])
   j = 0

   logger.debug('almacennnn aquiiii')
           logger.debug(list_products)

   # Recorremos los almacenes centrales y vamos moviendo los productos que hay
   # en el almacen de recepción. Se van llenando en orden los almacenes centrales.
   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
      cantidad_aux = fabrica['totalSpace'].to_i - fabrica['usedSpace'].to_i
      if list_products[:status]
          list_products[:result].each do |item|
          if j < cantidad_aux
            request_mov  = stock_aux.mover_stock(item['_id'],fabrica['_id'])
              #almacen_recepcion['_id'])
            response_mov = request_mov.run
            j = j + 1
          else
            j = 0
            break
          end
        end
      end
   end
    logger.debug("...Fin mover productos")
   return  {:status => true}
end

###############################################
################# PROVEEDOR ###################
###############################################

# Metodo para recibir orden de compra y procesarla
# o rechazarla segun sea el caso
def recibir_oc
  logger.debug("...Inicio recibir oc")
  id_order = params.require(:idoc)
  url      = Rails.configuration.oc_api_url + "obtener/" + id_order
  request  = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  oc_order = JSON.parse(response.body)[0]
  product = Product.where('sku = ?',oc_order['sku']).first
  if product.nil?
    OrdersController.new.rechazar_oc(id_order,'No hay producto en existencia')
    data_result = {:aceptado => false, :idoc => id_order }
    #Spawnling.new do
    #  sleep(5)
    #  logger.info('#####_produccion')
    #end
  else
    total = consultar_stock(oc_order['sku'])
    if(oc_order['cantidad'] < total)    
        response_recep = OrdersController.new.recepcionar_oc(id_order)
        if response_recep[:status] 
          Spawnling.new do
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
            response_inv = InvoicesController.new.emitir_factura(id_order)
            if response_inv[:status]
               result = response_inv[:result]
               order_obj.factura = Factura.create!({
                :_id    => result['_id'], 
                :bruto  => result['bruto'],
                :iva    => result['iva'], 
                :total  => result['total'] })
                order_obj.save
                enviar_factura(result)
            end  
          end
          data_result = {:aceptado => true, :idoc => id_order}
        else
            OrdersController.new.rechazar_oc(id_order,'No hay producto en existencia')
            data_result = {:error => response_recep [:result], :aceptado => false, :idoc => id_order}
        end
    else
        OrdersController.new.rechazar_oc(id_order,'No hay producto en existencia')
        data_result = {:aceptado => false, :idoc => id_order }
    end
  end
  logger.debug("...Fin recibir oc")
  respond_to do |format|
    format.json  { render json: data_result}
    format.html { render json: data_result }
  end
end

# Metodo para enviar facturas emitidas a los clientes 
def enviar_factura(factura)
  logger.debug("...Iniciar enviar factura")
  info = InfoGrupo.where('id_grupo = ?',factura['cliente']).first
  #url = 'http://integra'+info[:numero].to_s+'.ing.puc.cl/api/facturas/recibir/'+factura['_id'].to_s
  url = 'http://localhost:3000/api/facturas/recibir/'+factura['_id'].to_s
  request = Typhoeus::Request.new(
    url,
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run  
  logger.debug("...Fin enviar factura")
  return {:validado => true, :factura => factura}
end

# Metodo para notificar despachos a los clientes
def enviar_despacho(idfactura,cliente)
  logger.debug("...Inicio enviar despacho")
  info = InfoGrupo.where('id_grupo = ?',cliente).first
  #url = 'http://integra'+info[:numero].to_s+'.ing.puc.cl/api/despachos/recibir/'+idfactura.to_s
  url = 'http://localhost:3000/api/despachos/recibir/'+idfactura.to_s
  request = Typhoeus::Request.new(
    url,
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  logger.debug("...Fin enviar despacho")
  return {:validado => true}
end

# Metodo con el cual un proveedor verifica que
# han pagado una factura
def validar_pago
    logger.debug("...Inicio validar pago")
    idtrx     = params.require(:idtrx)
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:idtrx] = idtrx 
    result[:validado] = false
    if !idtrx.blank?
      # Se marca la factura como pagadá
      response_inv = InvoicesController.new.pagar_factura(idfactura)
      if response_inv[:status]
        result[:validado] = true
      end
      Spawnling.new do
        # Se procede a despachar lo establecido en la factura
        mover_despachar(idfactura)
      end
    end
    logger.debug("...Fin validar pago")
    respond_with result, json: result
end

# Metodo para mover los productos al almacen de despacho
# para su posterior envio
def mover_despachar(idfactura)
    logger.debug("...Inicio mover despachar")
   response_inv = InvoicesController.new.obtener_factura(idfactura)
   factura      = nil
   oc           = nil
   sku          = nil
   cantidad     = nil
       #logger.debug(response_inv)
   if response_inv[:status]
    factura = response_inv[:result]
    request_oc  = OrdersController.new.obtener_oc(factura[0]['oc'])
    if request_oc[:status]
      oc       = request_oc[:result]
      sku      = oc[0]['sku']
      cantidad = oc[0]['cantidad']
    end
   end
   stock_aux = StoresController.new
   product   = Product.where('sku = ?',sku).first
   precio    = product['precio_unitario'] 
   grupo     = InfoGrupo.where('id_grupo = ?',oc[0]['cliente']).first
   almacen_cliente = grupo['id_almacen']
   almacen_despacho =  Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,true,false).first
   j = 0
   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
      list_products = stock_aux.get_stock(sku,fabrica['_id'])
      if list_products[:status]
        #new_list = list_products[:result].select{|aux| aux['despachado'] == false}

        list_products[:result].each do |item|
          if j < cantidad                 
            request_mov  = stock_aux.mover_stock(item['_id'],almacen_despacho['_id'])
            response_mov = request_mov.run 
            if response_mov.success?  
            logger.debug('aquiii estoy')  
            result_mov_prod = JSON.parse(response_mov.body)       
            #logger.debug(item) 
            #logger.debug(result_mov_prod)
            logger.debug(result_mov_prod['_id'])    
            logger.debug(almacen_cliente) 
            logger.debug(oc[0]['_id'],) 
            logger.debug(precio)                 
               request_stock = stock_aux.mover_stock_bodega(result_mov_prod['_id'],almacen_cliente,oc[0]['_id'],precio)
               response_stock = request_stock.run
               logger.debug(response_stock.body)
               if response_stock.success?
                  logger.debug('entro a stock')
                  result_stock = JSON.parse(response_stock.body)
                  logger.debug(result_stock)  
               end

            end
          else
            break
          end
          j = j + 1
        end
        enviar_despacho(factura[0]['_id'],factura[0]['cliente'])
      end
   end
    logger.debug("...Fin mover despacho")
   return  {:status => true}
end

########################################################################
########################## GENERAL #####################################
########################################################################

# Metodo para consultar el stock de un sku
# en los almacenes principales
def consultar_stock(sku = nil)
  logger.debug(Rails.application.config.oc_api_url)
  sku_code = sku || params.require(:sku)
  stock = 0
  hydra = Typhoeus::Hydra.new
   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
    request = StoresController.new.request_sku_with_stock(fabrica['_id'])
    request.on_complete do |response|
      value = JSON.parse(response.body).select { |item| item['_id'] == sku_code }.first()
      if !value.nil?
        stock = stock + value['total'];
      end
    end
    hydra.queue(request)
  end
  response = hydra.run
  if sku.nil?
    respond_to do |format|
      format.json  { render json: {:stock => stock, :sku => sku_code} }
      format.html  { render json: {:stock => stock, :sku => sku_code} }
    end
  else
    return stock
  end
end

end
