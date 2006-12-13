#!/usr/bin/env ruby
# TestFactory -- ydim -- 16.01.2006 -- hwyss@ywesee.com

$: << File.dirname(__FILE__)
$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'stub/odba'
require 'flexmock'
require 'ydim/factory'

module YDIM
	class TestFactory < Test::Unit::TestCase
		def setup
			@serv = FlexMock.new
			@factory = Factory.new(@serv)
		end
		def test_create_invoice
			id_server = FlexMock.new
			invoices = {}
			config = FlexMock.new
			@serv.mock_handle(:config) { config }
			@serv.mock_handle(:id_server) { id_server }
			@serv.mock_handle(:invoices) { invoices }
			@serv.mock_handle(:debitors) { debitors }
			config.mock_handle(:invoice_number_start) { 13 }	
			id_server.mock_handle(:next_id) { |key, start|
				assert_equal(13, start)
				assert_equal(:invoice, key)
				24
			}
			debitor = FlexMock.new
			debitor.mock_handle(:add_invoice) { |inv|
				assert_instance_of(Invoice, inv)
			}
			dinvs = nil
			debitor.mock_handle(:invoices) { 
				dinvs = FlexMock.new
				dinvs.mock_handle(:odba_store, 1)
				dinvs
			}
			invoice = nil
			assert_nothing_raised { invoice = @factory.create_invoice(debitor) }
			assert_instance_of(Invoice, invoice)
			assert_equal({24 => invoice}, invoices)
			dinvs.mock_verify
	end
		def test_create_autoinvoice
			id_server = FlexMock.new
			config = FlexMock.new
			@serv.mock_handle(:config) { config }
			@serv.mock_handle(:id_server) { id_server }
			@serv.mock_handle(:debitors) { debitors }
			config.mock_handle(:invoice_number_start) { 13 }	
			id_server.mock_handle(:next_id) { |key, start|
				assert_equal(13, start)
				assert_equal(:autoinvoice, key)
				24
			}
			debitor = FlexMock.new
			debitor.mock_handle(:add_autoinvoice) { |inv|
				assert_instance_of(AutoInvoice, inv)
			}
			dinvs = nil
			debitor.mock_handle(:autoinvoices) { 
				dinvs = FlexMock.new
				dinvs.mock_handle(:odba_store, 1)
				dinvs
			}
			invoice = nil
			assert_nothing_raised { 
        invoice = @factory.create_autoinvoice(debitor) }
			assert_instance_of(AutoInvoice, invoice)
			dinvs.mock_verify
	end
	end
end
