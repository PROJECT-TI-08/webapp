class ApiController < ApplicationController
   #before_filter :authenticate_user!

def enviar_factura(factura)
  info = InfoGrupo.where('id_grupo = ?',factura['cliente']).first
  url = 'integra'+info['numero']+'.ing.puc.cl/api/facturas/recibir/'+factura['_id']
  request = Typhoeus::Request.new(
    'http://integra8.ing.puc.cl/api/facturas/recibir/' + factura['_id'], 
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
  return {:validado => true, :factura => factura}
end

def enviar_transaccion(trx,idfactura)
  info = InfoGrupo.where('id_banco = ?',trx[0]['cliente']).first
  url = 'integra'+info['numero']+'.ing.puc.cl/api/pagos/recibir/'+trx[0]['_id']
  request = Typhoeus::Request.new(
    'http://integra8.ing.puc.cl/api/pagos/recibir/' + trx[0]['_id'], 
    method: :get,
    params:{
      idfactura: idfactura
    },
    headers: { ContentType: "application/json"})
  response = request.run
  return {:validado => true, :trx => trx}
end


# Metodo para recibir orden de compra y procesarla
# o rechazarla segun sea el caso
def recibir_oc
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
    Spawnling.new do
      sleep(10)
      logger.info('#####_produccion')
    end
  else
    total = consultar_stock(oc_order['sku'])
      #data.product_stores.map(&:qty).sum
    if(oc_order['cantidad'] < total)    
        request_recep = OrdersController.new.recepcionar_oc(id_order)
        if request_recep[:status] 
          #################################################
          Spawnling.new do
            sleep(10)
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
  respond_with data_result ,json: data_result
end


def validar_factura
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:validado] = true
    result[:idfactura] = idfactura 
         logger.info('#####_validar_factura'+result.to_s)
    respond_with result, json: result
end


def validar_pago
    idtrx     = params.require(:idtrx)
    idfactura = params.require(:idfactura)
    result = Hash.new 
    result[:idtrx] = idtrx 
    result[:validado] = true
    #Spawnling.new do
    #  sleep(10)
    #  mover_despachar
    #end
    logger.info('#####_validar_pago'+result.to_s)
    respond_with result, json: result
end

def mover_despachar(sku = nil, idfactura = nil)
   sku =  params.require(:sku)
   stock_aux = StoresController.new
   product   = Product.where('sku = ?',sku).first
   precio    = product['precio_unitario'] 
   result = Array.new
   Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
      list_products = stock_aux.get_stock(sku,fabrica['_id'])
      if list_products[:status]
        new_list = list_products[:result].select{|aux| aux['despachado'] == false}
        new_list.each do |item|
          result.push(item)
          #request_mov = stock_aux.mover_stock(item['_id'],fabrica['_id'])
          #response_mov = request_mov.run
          #if response_mov.success?                              
          #    stock_aux.despachar_stock(item['_id'],'',precio)
          #end
        end
      end
   end
   respond_with result, json: result
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
