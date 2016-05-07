User.create!({:email => "devucjd01@gmail.com",:username => 'admin', :admin => true, :password => "dev082016", :password_confirmation => "dev082016" })

########################## Datos iniciales de productos #############################

Product.create!({:sku => '18',:nombre => 'Pastel',:unidades =>'Un', :costo_produccion_unitario => 2140,
	  				   :lote_produccion => 200, :tiempo_medio_produccion => 0.941, :tipo => 'pp', 
	  				   :precio_unitario => 9474 })

Product.create!({:sku => '24',:nombre => 'Tela de Seda',:unidades =>'Mts', :costo_produccion_unitario => 1442,
				   :lote_produccion => 400, :tiempo_medio_produccion => 0.695, :tipo => 'pp',  
				   :precio_unitario => 2774 })

Product.create!({:sku => '26',:nombre => 'Sal',:unidades =>'Kg', :costo_produccion_unitario => 753,
				   :lote_produccion => 144, :tiempo_medio_produccion => 0.784, :tipo => 'mp',
				   :precio_unitario => 926 })

Product.create!({:sku => '37',:nombre => 'Lino',:unidades =>'Mts', :costo_produccion_unitario => 764,
				   :lote_produccion => 1200, :tiempo_medio_produccion => 2.797, :tipo => 'mp',  
				   :precio_unitario => 916 })

Product.create!({:sku => '23',:nombre => 'Harina',:unidades =>'Kg', :costo_produccion_unitario => 1534,
				   :lote_produccion => 500, :tiempo_medio_produccion => 3.950, :tipo => 'pp',  
				   :precio_unitario => 4294 })

Product.create!({:sku => '2',:nombre => 'Huevo',:unidades =>'Un', :costo_produccion_unitario => 513,
				   :lote_produccion => 150, :tiempo_medio_produccion => 3.736, :tipo => 'mp',  
				   :precio_unitario => 718 })

Product.create!({:sku => '7',:nombre => 'Leche',:unidades =>'Lts', :costo_produccion_unitario => 941,
				   :lote_produccion => 1000, :tiempo_medio_produccion => 4.248, :tipo => 'mp',  
				   :precio_unitario => 1307 })

Product.create!({:sku => '33',:nombre => 'Seda',:unidades =>'Kg', :costo_produccion_unitario => 834,
				   :lote_produccion => 90, :tiempo_medio_produccion => 0.711, :tipo => 'mp',  
				   :precio_unitario => 992 })

Formula.create!({:sku_parent => '18',:sku_child => '23',:requerimiento => 72, :precio => 4294})

Formula.create!({:sku_parent => '18',:sku_child => '2',:requerimiento => 71, :precio => 718})

Formula.create!({:sku_parent => '18',:sku_child => '7',:requerimiento => 67, :precio => 1307})

Formula.create!({:sku_parent => '24',:sku_child => '33',:requerimiento => 444, :precio => 992})


InfoGrupo.create!({:numero => 1, :id_grupo => '572aac69bdb6d403005fb042',:id_banco => '572aac69bdb6d403005fb04e', 
	:id_almacen => '572aad41bdb6d403005fb066'})
InfoGrupo.create!({:numero => 2, :id_grupo => '572aac69bdb6d403005fb043',:id_banco => '572aac69bdb6d403005fb04f', 
	:id_almacen => '572aad41bdb6d403005fb0ba'})
InfoGrupo.create!({:numero => 3, :id_grupo => '572aac69bdb6d403005fb044',:id_banco => '572aac69bdb6d403005fb050', 
	:id_almacen => '572aad41bdb6d403005fb1bf'})
InfoGrupo.create!({:numero => 4, :id_grupo => '572aac69bdb6d403005fb045',:id_banco => '572aac69bdb6d403005fb051', 
	:id_almacen => '572aad41bdb6d403005fb208'})
InfoGrupo.create!({:numero => 5, :id_grupo => '572aac69bdb6d403005fb046',:id_banco => '572aac69bdb6d403005fb052', 
	:id_almacen => '572aad41bdb6d403005fb278'})
InfoGrupo.create!({:numero => 6, :id_grupo => '572aac69bdb6d403005fb047',:id_banco => '572aac69bdb6d403005fb053', 
	:id_almacen => '572aad41bdb6d403005fb2d8'})
InfoGrupo.create!({:numero => 7, :id_grupo => '572aac69bdb6d403005fb048',:id_banco => '572aac69bdb6d403005fb054', 
	:id_almacen => '572aad41bdb6d403005fb3b9'})
InfoGrupo.create!({:numero => 8, :id_grupo => '572aac69bdb6d403005fb049',:id_banco => '572aac69bdb6d403005fb056', 
	:id_almacen => '572aad41bdb6d403005fb416'})
InfoGrupo.create!({:numero => 9, :id_grupo => '572aac69bdb6d403005fb04a',:id_banco => '572aac69bdb6d403005fb057', 
	:id_almacen => '572aad41bdb6d403005fb4b8'})
InfoGrupo.create!({:numero => 10, :id_grupo => '572aac69bdb6d403005fb04b',:id_banco => '572aac69bdb6d403005fb058', 
	:id_almacen => '572aad41bdb6d403005fb542'})
InfoGrupo.create!({:numero => 11, :id_grupo => '572aac69bdb6d403005fb04c',:id_banco => '572aac69bdb6d403005fb059', 
	:id_almacen => '572aad41bdb6d403005fb5b9'})
InfoGrupo.create!({:numero => 12, :id_grupo => '572aac69bdb6d403005fb04d',:id_banco => '572aac69bdb6d403005fb05a', 
	:id_almacen => '572aad42bdb6d403005fb69f'})	

  result_almacenes = StoresController.new.get_almacenes
  if(result_almacenes[:status])
      result_almacenes[:result].each() do |item|         
            Store.create!({:_id => item['_id'],:pulmon => item['pulmon'],:despacho => item['despacho'],
            	:recepcion => item['recepcion'], :totalSpace => item['totalSpace'], :usedSpace => item['usedSpace']})
      end
	  end

  hydra = Typhoeus::Hydra.new
  Store.where('pulmon = ? AND despacho = ? AND recepcion = ?',false,false,false).each do |fabrica|
    request = StoresController.new.request_sku_with_stock(fabrica['_id'])
    request.on_complete do |response|

		JSON.parse(response.body).map { |item| 
			product_aux = Product.where(sku: item['_id']).first
			store_aux   = Store.where(_id: fabrica['_id']).first
			product_aux.product_stores.create!({:store_id => store_aux.id,
				:qty => item['total']})
		}
    end
    hydra.queue(request)
  end
  response = hydra.run	

