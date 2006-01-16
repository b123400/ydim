#!/usr/bin/env ruby
# TestItem -- ydim -- 12.01.2006 -- hwyss@ywesee.com


$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'ydim/item'

module YDIM
	class TestItem < Test::Unit::TestCase
		def test_initialize
			time = Time.now
			data = {
				:quantity => 1, :unit => 'St�ck', :text => 'Item 1', :price => 10.00,
				:vat_rate => 7.6, :data => {}, :time => time, :expiry_time => nil
			}
			item = Item.new(data)
			assert_equal(1, item.quantity)
			assert_equal('St�ck', item.unit)
			assert_equal('Item 1', item.text)
			assert_equal(10.0, item.price)
			assert_equal(7.6, item.vat_rate)
			assert_equal({}, item.data)
			assert_equal(time, item.time)
			assert_equal(nil, item.expiry_time)
		end
		def test_total_netto
			item = Item.new
			item.quantity = 3.5
			item.price = 2.0
			assert_equal(7.0, item.total_netto)
		end
		def test_total_brutto
			item = Item.new
			item.quantity = 3.5
			item.price = 2.0
			item.vat_rate = 10
			assert_equal(7.7, item.total_brutto)
		end
	end
end
