if Rails.env.production?
	Rails.application.config.oc_api_url   	  = 'http://moto.ing.puc.cl/oc/'
	Rails.application.config.inv_api_url  	  = 'http://moto.ing.puc.cl/facturas/'
	Rails.application.config.bank_api_url     = 'http://moto.ing.puc.cl/banco/'
	Rails.application.config.bo_api_url       = 'http://integracion-2016-prod.herokuapp.com/bodega/'

	Rails.application.config.sftp_url         = 'moto.ing.puc.cl'
	Rails.application.config.sftp_url_user    = 'integra8'
	Rails.application.config.sftp_url_pass    = 'JqujFuHG'

	Rails.application.config.bo_key           = 'pIGlKCGCyQqB9Us'
	Rails.application.config.id_grupo         = '572aac69bdb6d403005fb049'
	Rails.application.config.bank_account     = '572aac69bdb6d403005fb056'

	Rails.application.config.grupos_skus = [{:grupo => '572aac69bdb6d403005fb043', :numero => '2', :sku => 2},
	{:grupo => '572aac69bdb6d403005fb04d', :numero => '12', :sku => 7},{:grupo => '572aac69bdb6d403005fb048', :numero => '7', :sku => 23},
	{:grupo => '572aac69bdb6d403005fb046', :numero => '5', :sku => 33}] 
else
	Rails.application.config.oc_api_url       = 'http://mare.ing.puc.cl/oc/'
	Rails.application.config.inv_api_url  	  = 'http://mare.ing.puc.cl/facturas/'
	Rails.application.config.bank_api_url 	  = 'http://mare.ing.puc.cl/banco/'
	Rails.application.config.bo_api_url       = 'http://integracion-2016-dev.herokuapp.com/bodega/'

	Rails.application.config.sftp_url         = 'mare.ing.puc.cl'
	Rails.application.config.sftp_url_user    = 'integra8'
	Rails.application.config.sftp_url_pass    = 'UADkEXqZ'

	Rails.application.config.bo_key           = 'pIGlKCGCyQqB9Us'
	Rails.application.config.id_grupo         = '571262b8a980ba030058ab56'
	Rails.application.config.bank_account     = '571262c3a980ba030058ab5e'

	Rails.application.config.grupos_skus = [{:grupo => '571262b8a980ba030058ab50', :numero => '2', :sku => 2},
	{:grupo => '571262b8a980ba030058ab5a', :numero => '12', :sku => 7},{:grupo => '571262b8a980ba030058ab55', :numero => '7', :sku => 23},
	{:grupo => '571262b8a980ba030058ab53', :numero => '5', :sku => 33}] 
end
	
	








