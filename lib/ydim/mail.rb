#!/usr/bin/env ruby
# Mail -- ydim -- 18.01.2006 -- hwyss@ywesee.com

require 'net/smtp'
require 'rmail'
require 'ydim/smtp_tls'

module YDIM
	module Mail
		def Mail.body(config, debitor, invoice)
			salutation = config.salutation[debitor.salutation.to_s]
			sprintf(config.mail_body, salutation, debitor.contact, invoice.description)
		end
		def Mail.send_invoice(config, invoice, sort_args={})
			debitor = invoice.debitor
			to = debitor.email
			subject = sprintf('Rechnung %s #%i, %s', debitor.name,
							invoice.unique_id, invoice.description)
			invoice_name = sprintf("%s.pdf", subject.tr(' /', '_-'))
			mpart = RMail::Message.new
			header = mpart.header
			header.to = to
      cc = header.cc = debitor.emails_cc
			header.from = config.mail_from
      header.subject = encode_subject config, subject
      header.date = Time.now
			tpart = RMail::Message.new
			mpart.add_part(tpart)
			tpart.header.add('Content-Type', 'text/plain', nil, 
                       'charset' => config.mail_charset)
			tpart.body = body(config, debitor, invoice)
			fpart = RMail::Message.new
			mpart.add_part(fpart)
			header = fpart.header
			header.add('Content-Type', 'application/pdf')
			header.add('Content-Disposition', 'attachment', nil,
				{'filename' => invoice_name })
			header.add('Content-Transfer-Encoding', 'base64')
			fpart.body = [invoice.to_pdf(sort_args)].pack('m')
			recipients = config.mail_recipients.dup.push(to).concat(cc).uniq
			Net::SMTP.start(config.smtp_server, config.smtp_port,
                      config.smtp_domain, config.smtp_user, config.smtp_pass,
                      config.smtp_authtype) { |smtp|
				recipients.each { |recipient|
					smtp.sendmail(mpart.to_s, config.smtp_user, recipient)
				}
			}
			recipients
    rescue Timeout::Error
      retries ||= 3
      if retries > 0
        sleep 3 - retries
        retries -= 1
        retry
      else
        raise
      end
		end
    def Mail.send_reminder(config, autoinvoice)
      subject = autoinvoice.reminder_subject.to_s.strip
      subject.gsub! %r{<year>\s*}, ''
      subject.gsub! %r{\s*</year>}, ''
      body = autoinvoice.reminder_body.to_s.strip
      body.gsub! %r{<invoice>\s*}, ''
      body.gsub! %r{\s*</invoice>}, ''
      unless(subject.empty? || body.empty?)
        debitor = autoinvoice.debitor
        to = debitor.email
        mpart = RMail::Message.new
        header = mpart.header
        header.to = to
        cc = header.cc = debitor.emails_cc
        header.from = config.mail_from
        header.subject = encode_subject config, subject
        header.date = Time.now
        header.add('Content-Type', 'text/plain', nil, 
                   'charset' => config.mail_charset)
        mpart.body = body
        recipients = config.mail_recipients.dup.push(to).concat(cc).uniq
        Net::SMTP.start(config.smtp_server, config.smtp_port,
                        config.smtp_domain, config.smtp_user, config.smtp_pass,
                        config.smtp_authtype) { |smtp|
          recipients.each { |recipient|
            smtp.sendmail(mpart.to_s, config.smtp_user, recipient)
          }
        }
        recipients
      end
		end
    def Mail.encode_subject(config, subject)
      encoded = [subject].pack('M').gsub("=\n", '').gsub(' ', '=20')
      sprintf("=?%s?q?%s?=", config.mail_charset, encoded)
    end
	end
end
