Rails.application.routes.draw do
    devise_for :users
    root to: 'application#angular'    

    resources :orders, only: [:index, :show] do
    end

    resources :stores, only: [:index, :show] do
    end

    resources :products, only: [:index, :show] do
    end
    
    ############### API ##################
    get 'api/oc/recibir/:idoc'             => 'api#recibir_oc'
 
    get 'api/consultar/:sku'               => 'api#consultar_stock'

    get 'api/facturas/recibir/:idfactura'  => 'api#validar_factura'

    get 'api/pagos/recibir/:idtrx'         => 'api#validar_pago'

    get 'api/despachos/recibir/:idfactura' => 'api#validar_despacho'

    post 'api/facturas/boleta'             => 'invoices#crear_boleta'

    get 'api/documentacion', :to => redirect('/documentation.html')

    ######################################

end
