Rails.application.routes.draw do
    devise_for :users
    root to: 'application#angular'    

    resources :orders, only: [:index, :show] do
    end
    
    ############### API ##################
    post 'api/oc/recibir/:idoc'            => 'api#recibir_oc'
  
    get 'api/consultar/:sku'               => 'api#consultar_stock'

    post 'api/facturas/recibir/:idfactura' => 'api#validar_factura'

    post 'api/pagos/recibir/:idtrx'        => 'api#validar_pago'
    ######################################

    get 'api/mover/:sku' => 'api#mover_despachar'

end
