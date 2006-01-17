#!/usr/bin/env ruby
# Server -- ydim -- 10.01.2006 -- hwyss@ywesee.com

require 'logger'
require 'needle'
require 'odba/id_server'
require 'rrba/server'
require 'ydim/autoinvoicer'
require 'ydim/client'
require 'ydim/debitors'
require 'ydim/factory'
require 'ydim/root_user'
require 'ydim/util'

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
			@serv.register(:debitors) {
				ODBA.cache.fetch_named('companies', self) {
					Debitors.new
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
			@serv.register(:invoices) {
				ODBA.cache.fetch_named('invoices', self) {
					{}
				}
			}
			@serv.register(:logger) {
				logger
			}
			if(config.autoinvoice_hour)
				run_autoinvoice_thread
			end
		end
		def login(client, name=nil, &block)
			@serv.logger.debug(client.__drburi) { 'attempting login' }
			session = @serv.auth_server.authenticate(name, &block)
			session.serv = @serv
			session.client = client
			@serv.logger.info(session.whoami) { 'login' }
			session
		rescue Exception => error
			@serv.logger.error('unknown user') { 
				[error.class, error.message].join(' - ') }
			raise
		end
		def logout(session)
			@serv.logger.info(session.whoami) { 'logout' }
			nil
		end
		def ping
			true
		end
		private
		def run_autoinvoice_thread
			@autoinvoicer = Thread.new { 
				Thread.current.abort_on_exception = true
				loop {
					now = Time.now
					next_run = Time.local(now.year, now.month, now.day,
																@serv.config.autoinvoice_hour)
					sleepy_time = next_run - now
					if(sleepy_time < 0)
						sleepy_time += SECONDS_IN_DAY
						next_run += SECONDS_IN_DAY
					end
					@serv.logger.info('AutoInvoicer') {
						sprintf("next run %s, sleeping %i seconds", 
										next_run.strftime("%c"), sleepy_time)
					}
					sleep(sleepy_time)
					AutoInvoicer.new(@serv).run
				}
			}
		end
	end
end
