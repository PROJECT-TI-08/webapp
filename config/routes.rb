Rails.application.routes.draw do
  devise_for :users
  root to: 'application#angular'

    resources :orders, only: [:index, :show] do
    end
    ############### API ##################
    post 'api/oc/recibir/:idoc'       => 'api#recibir_oc'
    get 'api/consultar/:sku' => 'api#consultar_stock'
    get 'api/test_spawn' => 'api#test_spawn'

    post 'api/facturas/recibir/:idfactura' => 'api#validar_factura'

    post 'api/pagos/recibir/:idtrx' => 'api#validar_pago'


    get 'api/crear_oc' => 'orders#crear_oc'


    get 'api/test' => 'thread#test'

    ######################################

    #get 'order_oc/get_sku_with_stock' => 'orders#get_sku_with_stock'
    #get 'order_oc/get_ftp' => 'orders#get_orders_by_ftp'
    #get 'order_oc/get_oc'  => 'orders#get_remote_oc'
    #get 'api/consultar_sku_almacen/:sku/:almacen_id' => 'api#consultar_sku_por_almacen'

end
