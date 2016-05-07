class StoresController < ApplicationController
   #before_filter :authenticate_user!

def index
    respond_with Store.all
  end
  def show
    respond_with Store.find(params[:id])
  end 
###########################################
############### PRODUCCIÓN ################
###########################################

def abastecer_productos
	Products.all.each do |item|
		stock_actual = ApiController.new.consultar_stock(item['sku'])
		if(stock_actual <= item['lote_produccion'].to_i * 2)
			producir(item['sku'],item['lote_produccion'].to_i * 2)
		end
	end
end

def comprar_insumo(sku, cantidad)
  logger.debug('...Inicio comprar insumo')
  proveedor = Rails.configuration.grupos_skus.detect{|aux| aux[:sku] == sku.to_i}
  url = 'http://integra'+proveedor[:numero].to_s+'.ing.puc.cl/api/consultar/'+sku.to_s
  request = Typhoeus::Request.new(
    url,
    method: :get,
    headers: { ContentType: "application/json"})
  response = request.run
  if response.success?
  	 datos = JSON.parse(response.body)
  	 cantidad_comprar = 0
  	 if datos['stock'] >= cantidad
  	 	cantidad_comprar = cantidad
  	 else
  	 	 cantidad_comprar = datos['stock']
  	 end
  	 if cantidad_comprar > 0
	   	 product_aux = Product.where('sku = ?',sku).first
	   	 oc_object = {:canal => 'b2b', :cantidad => cantidad_comprar, :sku => sku, :proveedor => proveedor[:grupo], 
	   	 	:precioUnitario =>product_aux['precio_unitario'].to_i ,:cliente => Rails.configuration.id_grupo,
	   	 	:fechaEntrega => '162999999999234', :notas => 'na'}
	     obj_oc = OrdersController.new.crear_oc(oc_object)
	     logger.debug(obj_oc)
	     if obj_oc[:status] 
	     	oc_order = obj_oc[:result]
	     	logger.debug('...oc_order ok')
	     	url = 'http://integra'+proveedor[:numero].to_s+'.ing.puc.cl/api/oc/recibir/'+oc_order['_id'].to_s 
		    request = Typhoeus::Request.new(
		    url,
		    method: :get,
		    headers: { ContentType: "application/json"})
		    response = request.run
		    logger.debug(response.message_error)
		    if response.success?
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
              :estado             => oc_order['estado'],
              :tipo               => 2 })
		    else	
		    	OrdersController.new.anular_oc(oc_order['_id'],'Error')
		    end
	     end
	 end
  end
end

def producir(sku, cantidad)
logger.debug('...Inicia producción')
   product = Product.where('sku = ?', sku).first
   indicador = cantidad.to_f / product[:lote_produccion].to_f
   cantidad_aux = 0
   mod = indicador.divmod 1
   if mod[1] == 0
       cantidad_aux = indicador.to_i * product[:lote_produccion].to_i
   else
       cantidad_aux = (indicador.to_i * product[:lote_produccion].to_i) + product[:lote_produccion].to_i
   end
   can_produce = true
   if(product[:tipo] == 'pp')
   Formula.where('sku_parent = ?', sku).each do |item|
   			  	logger.debug(item)
   	   cantidad_total = item['requerimiento'] * cantidad_aux
       stock_aux = ApiController.new.consultar_stock(item.sku_child)
	   if stock_aux < cantidad_total
		  Spawnling.new do
		  	comprar_insumo(item.sku_child, cantidad_total)
		  end
		  can_produce = false
	   end
    end
   end

   if can_produce
   	logger.debug('...Puede producir')
	   	result_cuenta = get_cuenta_fabrica
	   	product_aux = Product.where('sku = ?',sku).first
	   	logger.debug(result_cuenta[:result])
	   	if result_cuenta[:status]
	   		cuenta_destino = result_cuenta[:result]['cuentaId']
			result_bank = BankController.new.transferir(product_aux['costo_produccion_unitario'].to_f * cantidad_aux.to_f,
				Rails.configuration.bank_account,cuenta_destino);

				logger.debug(result_bank[:result])
			if result_bank[:status]
				trxId = result_bank[:result]['_id']
				result_producir = producir_stock(sku,trxId,cantidad_aux)
					logger.debug('before run')
				response_producir = result_producir.run
				logger.debug(JSON.parse(response_producir.body))
				if response_producir.success?
					result_pro = JSON.parse(response_producir.body)
					logger.debug(result_pro)
				end
			end
		end   	
   end
end

############################################################

def get_almacenes
  url    = Rails.configuration.bo_api_url + "almacenes"
  hmac   = crear_hmac('GET')
  request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { 
      ContentType:   "application/json",
      Authorization: "INTEGRACION grupo8:"+hmac
      })

  response = request.run
  if response.success?                 
    return {:status => true, :result => JSON.parse(response.body)}               
  else
    return {:status => false}
  end
end

def request_sku_with_stock(fabrica_id)
	url    = Rails.configuration.bo_api_url + "skusWithStock"
    hmac   = crear_hmac('GET' + fabrica_id)
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    params: { 
      almacenId: fabrica_id 
    },
  headers: { 
    ContentType:   "application/json",
    Authorization: "INTEGRACION grupo8:" + hmac
    })
    return request
end

def get_sku_with_stock
    hydra  = Typhoeus::Hydra.new
    result = Array.new
    Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
      request = request_sku_with_stock(fabrica['_id'])
      request.on_complete do |response|
      	JSON.parse(response.body).map { |item| 
        	result.push(item)
      	}
      end
      hydra.queue(request)
    end
    response = hydra.run  
  	return result
  end

  def get_stock(sku_code,almacen_id)
	  url    = Rails.configuration.bo_api_url + "stock"
	  hmac   = crear_hmac('GET'+almacen_id + sku_code)
	  request = Typhoeus::Request.new(
	    url, 
	    method: :get,
	    params: { 
	        almacenId: almacen_id, 
	        sku:       sku_code,
	        limit:     200
	      },
	    headers: { 
	      ContentType:   "application/json",
	      Authorization: "INTEGRACION grupo8:" + hmac
	      })
	  response = request.run
	  if response.success?                 
	    return {:status => true, :result => JSON.parse(response.body)}               
	  else
	    return {:status => false, :result =>[]}
	  end
  end

  def mover_stock(product_id,almacen_id)
  	  url     = Rails.configuration.bo_api_url + "moveStock"
  	  hmac    = crear_hmac('POST' + product_id + almacen_id) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :post,
	  body: { 
	    productoId: product_id,
	    almacenId:  almacen_id
	  },
	  headers: { 
	  	ContentType:   "application/json",
	  	Authorization: "INTEGRACION grupo8:" + hmac
	  })
	  return request
  end

  def mover_stock_bodega(product_id,almacen_id,oc_number,precio)
  	  url   = Rails.configuration.bo_api_url + "moveStockBodega"
  	  hmac    = crear_hmac('POST' + product_id + almacen_id) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :post,
	  body: { 
	    productoId: product_id,
	    almacenId:  almacen_id,
	    oc:         oc_number, 
	    precio:   	precio.to_i
	  },
	  headers: { 
	  	ContentType:   "application/json",
	  	Authorization: "INTEGRACION grupo8:" + hmac
	  })
	  return request
  end

  def despachar_stock(product_id,direccion,precio,oc_number)
  	  url   = Rails.configuration.bo_api_url + "stock"
  	  hmac    = crear_hmac('DELETE' + product_id + direccion + precio.to_s + oc_number.to_s) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :delete,
	  body: { 
	    productoId: product_id,
	    direccion:  direccion,
	    precio:     precio.to_i,
	    oc:         oc_number
	  },
	  	 headers: 
	  	{'Content-Type' => "application/x-www-form-urlencoded",
	  	'Authorization' => "INTEGRACION grupo8:" + hmac	
	  })
	  return request
  end

  def producir_stock(sku, trxId, cantidad)
  	  url   = Rails.configuration.bo_api_url + "fabrica/fabricar"
  	  hmac    = crear_hmac('PUT' + sku.to_s + cantidad.to_s + trxId.to_s ) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :put,
	  body: { 
	    sku:      sku,
	    trxId:    trxId,
	    cantidad: cantidad.to_i
	  },
	  headers: 
	  	{'Content-Type' => "application/x-www-form-urlencoded",
	  	'Authorization' => "INTEGRACION grupo8:" + hmac	
	  })
	  return request
  end

  def get_cuenta_fabrica
	  url     = Rails.configuration.bo_api_url + "fabrica/getCuenta"
  	  hmac    = crear_hmac('GET') 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :get,
	  headers: { 
	  	ContentType:   "application/json",
	  	Authorization: "INTEGRACION grupo8:" + hmac
	  })
	  response = request.run
	  if response.success?                 
	    return {:status => true, :result => JSON.parse(response.body)}               
	  else
	    return {:status => false, :result => JSON.parse(response.body)}
	  end
  end

private

def crear_hmac(action_params)
  key    = Rails.configuration.bo_key
  data   = action_params
  digest = OpenSSL::Digest.new('sha1')
  hmac   = Base64.encode64(OpenSSL::HMAC.digest(digest, key, data)).chomp.gsub(/\n/,'')
  return hmac
end	

end
