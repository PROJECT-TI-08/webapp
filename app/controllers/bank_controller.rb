require 'net/sftp'
require 'typhoeus'
require 'nokogiri'

class BankController < ApplicationController
   #before_filter :authenticate_user!

def transferir(monto,origen,destino)
    url = Rails.configuration.bank_api_url + 'trx'
    request = Typhoeus::Request.new(
    url, 
    method: :put,
    body: {
      monto:   monto.to_i,
      origen:  origen,
      destino: destino
    },
    headers: {'Content-Type'=> "application/x-www-form-urlencoded"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result =>  JSON.parse(response.body)}
    end
  end

  def obtener_cuenta(cuenta)
    url = Rails.configuration.bank_api_url + 'cuenta/' + cuenta
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