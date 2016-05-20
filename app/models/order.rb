class Order < ActiveRecord::Base
	has_one :factura
  #def as_json(options = {})
  #  super()
  #end
end
