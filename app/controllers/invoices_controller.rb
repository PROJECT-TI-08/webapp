require 'net/sftp'
require 'typhoeus'
require 'nokogiri'

class InvoicesController < ApplicationController
   #before_filter :authenticate_user!


def emitir_factura(oc_number)
    url = Rails.configuration.inv_api_url_dev
    request = Typhoeus::Request.new(
    url, 
    method: :put,
    body: {
      oc: oc_number
      },
    headers: {'Content-Type'=> "application/x-www-form-urlencoded"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result => response.return_message}
    end
  end

  def obtener_factura(invoice_number)
    url = Rails.configuration.inv_api_url_dev + invoice_number
    request = Typhoeus::Request.new(
    url, 
    method: :get,
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result => response.return_message}
    end
  end

  def pagar_factura(invoice_number)
    url = Rails.configuration.inv_api_url_dev + 'pay'
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    body: {
      id: invoice_number
      },
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result => response.return_message}
    end
  end

   def rechazar_factura(invoice_number, motivo)
    url = Rails.configuration.inv_api_url_dev + 'reject'
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    body: {
      id: invoice_number,
      motivo: motivo
      },
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result => response.return_message}
    end
  end

  def anular_factura(invoice_number, motivo)
    url = Rails.configuration.inv_api_url_dev + 'reject'
    request = Typhoeus::Request.new(
    url, 
    method: :post,
    body: {
      id: invoice_number,
      motivo: motivo
      },
    headers: { ContentType: "application/json"})
    response = request.run
    if response.success?                 
       return {:status => true, :result =>  JSON.parse(response.body)}               
    else
       return {:status => false, :result => response.return_message}
    end
  end


  def recibir_factura(factura)
    request = Typhoeus::Request.new(
      'localhost:3000/api/facturas/recibir/' + factura['id'], 
      method: :post,
      body: {
        factura: JSON.parse(JSON.parse)
      },
      headers: { ContentType: "application/json"})
    response = request.run 
    return response.body
  end


end