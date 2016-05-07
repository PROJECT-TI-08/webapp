# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

#crontab -l
#whenever --update-crontab
set :environment, Rails.env 
#"development"
#set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

 every 24.hours do
   runner "OrdersController.new.get_orders_by_ftp1"
 end


 every 1.minutes do
   runner "OrdersController.new.process_order_first_time1"
 end

 every 1.minutes do
   runner "ApiController.new.mover_productos1"
 end


 every 1.hour do
   runner "OrdersController.new.process_order_second_time1"
 end
