class Factura < ActiveRecord::Base
	belongs_to :order
end
