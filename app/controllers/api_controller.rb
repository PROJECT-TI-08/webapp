class ApiController < ApplicationController
   #before_filter :authenticate_user!

def enviar_factura(factura)
  logger.debug("...Iniciar enviar factura")
  info = InfoGrupo.where('id_grupo = ?',factura['cliente']).first
  url = 'http://integra'+info['numero']+'.ing.puc.cl/api/facturas/recibir/'+factura['_id']
  #'http://localhost:3000/api/facturas/recibir/' + factura['_id'], 
  request = Typhoeus::Request.new(
    url,
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  Spawnling.new do
    # Se marca factura como pagadá
    request_inv = InvoicesController.new.pagar_factura(factura['_id'])
    if request_inv[:status]
        result = request_inv[:result]
        enviar_transaccion(result,factura['_id'])
    end  
  end
  logger.debug("...Fin enviar factura")
  return {:validado => true, :factura => factura}
end

def enviar_transaccion(trx,idfactura)
  logger.debug("...Inicio enviar transaccion")
  info = InfoGrupo.where('id_banco = ?',trx[0]['cliente']).first
  url = 'http://integra'+info['numero']+'.ing.puc.cl/api/pagos/recibir/'+trx[0]['_id']
  #'http://localhost:3000/api/pagos/recibir/' + trx[0]['_id'], 
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

def enviar_despacho(idfactura,cliente)
  logger.debug("...Inicio enviar despacho")
  info = InfoGrupo.where('id_banco = ?',cliente).first
  url = 'http://integra'+info['numero']+'.ing.puc.cl/api/despachos/recibir/'+idfactura
  #http://localhost:3000/api/despachos/recibir/' + idfactura, 
  request = Typhoeus::Request.new(
    url,
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  logger.debug("...Fin enviar despacho")
  return {:validado => true}
end


# Metodo para recibir orden de compra y procesarla
# o rechazarla segun sea el caso
def recibir_oc
  logger.debug("...Inicio recibir oc")
  id_order = params.require(:idoc)
  # url de la api de ordenes de compra (metodo obtener orden de compra)
  url = Rails.configuration.oc_api_url_dev + "obtener/" + id_order
  request = Typhoeus::Request.new(
  	url, 
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  oc_order = JSON.parse(response.body)[0]
  product = Product.where('sku = ?',oc_order['sku']).first
  if product.nil?
    #rechazar metodo
    OrdersController.new.rechazar_oc(id_order,'No hay producto en existencia')
    data_result = {:aceptado => false, :idoc => id_order }
    #Spawnling.new do
    #  sleep(5)
    #  logger.info('#####_produccion')
    #end
  else
    total = consultar_stock(oc_order['sku'])
      #data.product_stores.map(&:qty).sum
    if(oc_order['cantidad'] < total)    
        request_recep = OrdersController.new.recepcionar_oc(id_order)
        if request_recep[:status] 
          #################################################
          Spawnling.new do
            request_inv = InvoicesController.new.emitir_factura(id_order)
            if request_inv[:status]
                result = request_inv[:result]
                enviar_factura(result)
            end  
          end
          #################################################
          data_result = {:aceptado => true, :idoc => id_order}
        else
            data_result = {:error => request_recep [:result], :aceptado => false, :idoc => id_order}
        end
    else
      data_result = {:aceptado => false, :idoc => id_order}
    end
  end
  logger.debug("...Fin recibir oc")
  respond_with data_result ,json: data_result
end


def validar_factura
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:validado] = true
    result[:idfactura] = idfactura 
    logger.debug("...Validar factura")
    respond_with result, json: result
end


def validar_pago
    idtrx     = params.require(:idtrx)
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:idtrx] = idtrx 
    result[:validado] = true
    Spawnling.new do
      mover_despachar(idfactura)
    end
     logger.debug("...Validar pago")
    respond_with result, json: result
end


#Api necesaria para producir
def validar_despacho
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:idfactura] = idfactura 
    result[:validado] = true
     logger.debug("...Validar despachar")
    respond_with result, json: result
end

def mover_despachar(idfactura = nil)
   #idfactura =  params.require(:factura)
   result = Array.new
   response_inv = InvoicesController.new.obtener_factura(idfactura)
   factura_obj = nil
   oc_obj = nil
   sku = nil
   cantidad = nil
   if response_inv[:status]
    factura_obj = response_inv[:result]
    request_oc = OrdersController.new.obtener_oc(factura_obj[0]['oc'])
    if request_oc[:status]
      oc_obj = request_oc[:result]
      sku =  oc_obj[0]['sku']
      cantidad = oc_obj[0]['cantidad']
    end
   end
   stock_aux = StoresController.new
   product   = Product.where('sku = ?',sku).first
   precio    = product['precio_unitario'] 
   grupo = InfoGrupo.where('id_grupo = ?',oc_obj[0]['cliente']).first
   almacen_cliente = grupo['id_almacen']
   almacen_despacho =  Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,true,false).first

   j = 0
   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
      list_products = stock_aux.get_stock(sku,fabrica['_id'])
      if list_products[:status]
        new_list = list_products[:result].select{|aux| aux['despachado'] == false}
        new_list.each do |item|
          if j < cantidad
            #result.push(item)
            request_mov = stock_aux.mover_stock(item['_id'],almacen_despacho['_id'])
            response_mov = request_mov.run
            #result.push(item)
            #result.push(response_mov.body)
            if response_mov.success?                              
                stock_aux.mover_stock_bodega(item['_id'],almacen_cliente,oc_obj[0]['_id'],precio)
            end
          else
            break
          end
          j = j + 1
        end
        enviar_despacho(factura_obj[0]['_id'],factura_obj[0]['cliente'])
      end
   end
    logger.debug("...Fin mover despacho")
 #end
   #respond_with result, json: result
   return  true #{:despachado => true}
end

# Metodo para consultar el stock de un sku
# en los almacenes principales
def consultar_stock(sku = nil)
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
    respond_with stock, json: {:stock => stock, :sku => sku_code}
  else
    return stock
  end
end

end
