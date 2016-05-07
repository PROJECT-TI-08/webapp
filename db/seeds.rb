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


InfoGrupo.create!({:numero => 1, :id_grupo => '571262b8a980ba030058ab4f',:id_banco => '571262c3a980ba030058ab5b', 
	:id_almacen => '571262aaa980ba030058a147'})
InfoGrupo.create!({:numero => 2, :id_grupo => '571262b8a980ba030058ab50',:id_banco => '571262c3a980ba030058ab5c', 
	:id_almacen => '571262aaa980ba030058a14e'})
InfoGrupo.create!({:numero => 3, :id_grupo => '571262b8a980ba030058ab51',:id_banco => '571262c3a980ba030058ab5d', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 4, :id_grupo => '571262b8a980ba030058ab52',:id_banco => '571262c3a980ba030058ab5f', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 5, :id_grupo => '571262b8a980ba030058ab53',:id_banco => '571262c3a980ba030058ab61', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 6, :id_grupo => '571262b8a980ba030058ab54',:id_banco => '571262c3a980ba030058ab62', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 7, :id_grupo => '571262b8a980ba030058ab55',:id_banco => '571262c3a980ba030058ab60', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 8, :id_grupo => '571262b8a980ba030058ab56',:id_banco => '571262c3a980ba030058ab5e', 
	:id_almacen => '571262aaa980ba030058a31e'})
InfoGrupo.create!({:numero => 9, :id_grupo => '',:id_banco => '', :id_almacen => ''})
InfoGrupo.create!({:numero => 10, :id_grupo => '571262b8a980ba030058ab58',:id_banco => '571262c3a980ba030058ab63', 
	:id_almacen => '571262aaa980ba030058a40c'})
InfoGrupo.create!({:numero => 11, :id_grupo => '571262b8a980ba030058ab59',:id_banco => '571262c3a980ba030058ab64', 
	:id_almacen => ''})
InfoGrupo.create!({:numero => 12, :id_grupo => '571262b8a980ba030058ab5a',:id_banco => '571262c3a980ba030068ab65', 
	:id_almacen => ''})

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

