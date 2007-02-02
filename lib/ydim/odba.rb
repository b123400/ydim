#!/usr/bin/env ruby
# ODBA -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'odba'
require 'ydim/currency_converter'
require 'ydim/debitor'
require 'ydim/invoice'

module YDIM
	class CurrencyConverter
		include ODBA::Persistable
		ODBA_SERIALIZABLE = ['@conversions']
	end
	class Debitor
		include ODBA::Persistable
		ODBA_SERIALIZABLE = ['@address_lines', '@hosting_items']
    odba_index :email
    odba_index :name
    odba_index :unique_id
	end
	class Invoice
		include ODBA::Persistable
		ODBA_SERIALIZABLE = ['@items']
    odba_index :status
    odba_index :unique_id
	end
	class AutoInvoice
    odba_index :unique_id
	end
end
