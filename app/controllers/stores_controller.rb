class StoresController < ApplicationController
   #before_filter :authenticate_user!

# Cada cierto tiempo verificar
def abastecer_productos
	Products.all.each do |item|
		stock_actual = ApiController.new.consultar_stock(item['sku'])
		if(stock_actual <= item['stock_minimo'])
			producir(item['sku']) # o comprar 
		end
	end
end

def comprar_insumo(sku, cantidad)
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
	   	 	:precio =>product_aux['precio_unitario'] , :notas => ''}
	     obj_oc = OrdersController.new.crear_oc(oc_object)
	     if obj_oc['status'] 
	     	obj_oc_result = obj_oc['result']
	     	url = 'http://integra'+proveedor[:numero].to_s+'.ing.puc.cl/api/recibir/'+obj_oc_result['_id'].to_s 
		    request = Typhoeus::Request.new(
		    url,
		    method: :get,
		    headers: { ContentType: "application/json"})
		    response = request.run
		    if !response.success?
		    	OrdersController.new.anular_oc(obj_oc_result['_id'],'Error')
		    end
	     end
	 end
  end
end


# Segun el lote del producto, modificar la cantidad
def producir(sku, cantidad)
   product = Product.where('sku = ?',sku).first
   if(product[:tipo] == 'pp')
   can_produce = true
   Formulas.where('sku_parent = ?', sku).each do |item|
   	   cantidad_total = item['requerimiento'] * cantidad
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
	   	result_cuenta = get_cuenta_fabrica
	   	product_aux = Product.where('sku = ?',sku).first
	   	if result_cuenta['status']
	   		cuenta_destino = result_cuenta['result']['cuentaId']
			result_bank = BankController.new.transferir(product_aux['costo_produccion_unitario'] * cantidad,
				Rails.configuration.bank_account,cuenta_destino);
			if result_bank['status']
				trxId = result_bank['result']['_id']
				result_producir = producir_stock(sku,trxId,cantidad)
			end
		end   	
   end
end

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
  	#respond_with result, json: result
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
  	  hmac    = crear_hmac('PUT' + sku + trxId + cantidad) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :put,
	  body: { 
	    sku:      sku,
	    trxId:    trxId,
	    cantidad: cantidad
	  },
	  headers: { 
	  	ContentType:   "application/json",
	  	Authorization: "INTEGRACION grupo8:" + hmac
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
	    return {:status => false}
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
