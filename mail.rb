require 'net/smtp'

message = <<MESSAGE_END
From: TDS.monitor@docomo.ru <TDS.monitor@docomo.ru>
To: Admin <satorsight@gmail.com>
Subject: Enormous activity on TDS detected

Something went wrong, please, check those:

monitor.blinko.ru
ad.blinko.ru/admin/

MESSAGE_END

Net::SMTP.start('localhost') do |smtp|
  smtp.send_message message, 'TDS.monitor@docomo.ru', 'evgeniy.nikolaev@docomodigital.com'
  smtp.send_message message, 'TDS.monitor@docomo.ru', 'artem.prokopenko@docomodigital.com'
end