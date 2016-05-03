require 'net/sftp'
require 'typhoeus'
require 'nokogiri'

class BankController < ApplicationController
   #before_filter :authenticate_user!


def transferir(monto,origen,destino)
    url = Rails.configuration.oc_api_url_dev + 'trx'
    request = Typhoeus::Request.new(
    url, 
    method: :put,
    body: {
      monto:   monto,
      origen:  origen,
      destino: destino
    },
    headers: {'Content-Type'=> "application/x-www-form-urlencoded"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false}
    end
  end

  def obtener_cuenta(cuenta)
    url = Rails.configuration.oc_api_url_dev + 'cuenta/' + cuenta
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false}
    end
  end

end