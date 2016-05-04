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

def producir(sku)
   Formulas.where('sku_parent = ?', sku).each do |item|
       stock_aux = ApiController.new.consultar_stock(item.sku_child)
	   if stock_aux > item['requerimiento']
	   	##########CONSULTAR API OTROS GRUPOS##################
	   		#get_stock
	   	######################################################
	   	#Precio del excel
	   	 product_aux = Product.where('sku = ?',item.sku_child).first
	   	 oc_object = {:canal => 'b2b', :cantidad => 1000, :sku => item.sku_child, :proveedor =>'xxxx', 
	   	 	:precio =>product_aux['precio_unitario'] , :notas => ''}
	     OrdersController.new.crear_oc(oc_object)
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
	    precio:   	precio
	  },
	  headers: { 
	  	ContentType:   "application/json",
	  	Authorization: "INTEGRACION grupo8:" + hmac
	  })
	  return request
  end

  def despachar_stock(product_id,direccion,precio,oc_number)
  	  url   = Rails.configuration.bo_api_url + "stock"
  	  hmac    = crear_hmac('DELETE' + product_id + direccion + precio + oc_number) 
	  request = Typhoeus::Request.new(
	  url, 
	  method: :delete,
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
