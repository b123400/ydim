#!/usr/bin/env ruby
# Item -- ydim -- 11.01.2006 -- hwyss@ywesee.com

module YDIM
	class Item
		DATA_KEYS = [ :data, :expiry_time, :item_type, :price, :quantity, :text,
			:time, :unit, :vat_rate, ]
		attr_accessor *DATA_KEYS
		def initialize(data={})
			DATA_KEYS.each { |key|	
				instance_variable_set("@#{key}", data[key])
			}
		end
		def total_brutto
			total_netto + vat
		end
		def total_netto
			@quantity.to_f * @price.to_f
		end
		def vat
			total_netto * (@vat_rate.to_f / 100.0)
		end
	end
end
