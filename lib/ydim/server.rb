#!/usr/bin/env ruby
# encoding: utf-8
# YDIM::Server -- ydim -- 09.12.2011 -- mhatakeyama@ywesee.com
# YDIM::Server -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'ydim/server_config'
require 'logger'
require 'needle'
require 'odba/id_server'
require 'rrba/server'
require 'ydim/autoinvoicer'
require 'ydim/client'
require 'ydim/currency_converter'
require 'ydim/currency_updater'
require 'ydim/factory'
require 'ydim/root_user'
require 'ydim/util'
require 'odba/18_19_loading_compatibility'

module YDIM
	class Server
    SECONDS_IN_DAY = 24*60*60
		def initialize(config, logger)
			@serv = Needle::Registry.new
			@serv.register(:auth_server) { 
				auth = RRBA::Server.new
				root = RootUser.new(:root)
				root.name = config.root_name
				root.email = config.root_email
				root_key = config.root_key
				path = File.expand_path(root_key, config.conf_dir)
				path_or_key = File.exist?(path) ? path : root_key
				root.public_key = Util.load_key(path_or_key)
				auth.root = root
				auth
			}
			@serv.register(:clients) {
				ClientHandler.new(@serv)
			}
			@serv.register(:config) {
				config
			}
			@serv.register(:currency_converter) {
				ODBA.cache.fetch_named('currency_converter', self) { 
					CurrencyConverter.new	
				}
			}
			@serv.register(:factory) {
				Factory.new(@serv)
			}
			@serv.register(:id_server) { 
				ODBA.cache.fetch_named('id_server', self) {
					ODBA::IdServer.new
				}
			}
			@serv.register(:logger) {
				logger
			}
			if(hour = config.autoinvoice_hour)
				@autoinvoicer = repeat_at(hour, 'AutoInvoicer') {
					AutoInvoicer.new(@serv).run
				}
			end
			if(hour = config.currency_update_hour)
				if(@serv.currency_converter.known_currencies \
					 < @serv.config.currencies.size)
					CurrencyUpdater.new(@serv).run
				end
				@currency_updater = repeat_at(hour, 'CurrencyUpdater') {
					CurrencyUpdater.new(@serv).run
				}
			end
      @status_updater = repeat_at(1, 'StatusUpdater') {
        Invoice.all { |inv| inv.save }
      }
			@sessions = []
		end
		def login(client, name=nil, &block)
			@serv.logger.debug(client.__drburi) { "attempting login" }
			session = @serv.auth_server.authenticate(name, &block)
			session.serv = @serv
			session.client = client
			@serv.logger.info(session.whoami) { 'login' }
			@sessions.push(session)
			session
		rescue Exception => error
			@serv.logger.error('unknown user') { 
				[error.class, error.message].join(' - ') }
			raise
		end
		def logout(session)
			@serv.logger.info(session.whoami) { 'logout' }
			@sessions.delete(session)
			nil
		end
		def ping
			true
		end
		private
		def repeat_at(hour, thread_name)
			Thread.new { 
				Thread.current.abort_on_exception = true
				loop {
					now = Time.now
					next_run = Time.local(now.year, now.month, now.day, hour)
					sleepy_time = next_run - now
					if(sleepy_time < 0)
						sleepy_time += SECONDS_IN_DAY
						next_run += SECONDS_IN_DAY
					end
					@serv.logger.info(thread_name) {
						sprintf("next run %s, sleeping %i seconds", 
										next_run.strftime("%c"), sleepy_time)
					}
					sleep(sleepy_time)
					yield
				}
			}
		end
	end
end
