class ApiController < ApplicationController
   #before_filter :authenticate_user!

# Funcionalidad para hacer delays de las consultas
def test_spawn
Spawnling.new do
  logger.info("Inició...")
  sleep 11
  logger.info("Esperó 11 segundos y reanudó")
end
  respond_with true ,json: true
end


def recibir_factura(factura)
  request = Typhoeus::Request.new(
    'localhost:3000/api/facturas/recibir/' + factura['_id'], 
    method: :post,
    body: {
      factura: factura
    },
    headers: { ContentType: "application/json"})
  response = request.run

  #Spawnling.new do
    request_inv = InvoicesController.new.pagar_factura(id_order)
    if request_inv[:status]
        result = request_inv[:result]
        validar_transaccion(result['trx'])
    end  
  #end

  return {:validado => true, :factura => factura}
end

def validar_transaccion(trx)
  request = Typhoeus::Request.new(
    'localhost:3000/api/pagos/recibir/' + trx['_id'], 
    method: :post,
    body:{
      trx: trx
    },
    headers: { ContentType: "application/json"})
  response = request.ru
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
  data = Product.where('sku = ?',oc_order['sku']).first
  if data.nil?
    #rechazar metodo
    data_result = {:aceptado => false, :idoc => id_order }

    ##### EJECUTAR PRODUCIR ######
  else
    total = data.product_stores.map(&:qty).sum
    if(oc_order['cantidad'] < total)   
        request_recep = OrdersController.new.recepcionar_oc(id_order)
           if request_recep[:status] 
##############################################################
              #Spawnling.new do
                request_inv = InvoicesController.new.emitir_factura(id_order)
                if request_inv[:status]
                    result = request_inv[:result]
                    recibir_factura(result)
                end  
              #end
###############################################################
        else
            data_result = {:error => request_recep [:result]}
        end
    else
      data_result = {:aceptado => false}
    end
  end
  respond_with data_result ,json: data_result
end


def validar_factura
    idfactura = params.require(:idfactura)
    factura = params.require(:factura)
    factura_json = JSON.parse(factura)
    result = Hash.new 
    result[:validado] = true
    result[:factura] = factura 
    respond_with result, json: result
end


def validar_pago
    idtrx = params.require(:idtrx)
    trx = params.require(:trx)
    result = Hash.new 
    result[:trx] = trx 
    result[:validado] = true
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
