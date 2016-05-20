# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

#crontab -l
#whenever --update-crontab
set :environment, "production" 
#"development"
#set :output, {:error => "#{path}/log/cron_error.log", :standard => "#{path}/log/cron.log"}

#set :output, "#{path}/log/cron.log"

#job_type :runner, "{ cd #{@current_path} > /dev/null; } && RAILS_ENV='production' bundle exec rails runner ':task' :output"
job_type :runner, "cd #{@path} && RAILS_ENV='production' /home/administrator/.rvm/wrappers/ruby-2.3.1/bundle exec rails runner ':task' :output"


 every 30.minutes do
   runner "OrdersController.new.get_orders_by_ftp"
 end

 every 5.minutes do
   runner "OrdersController.new.process_order_first_time"
 end

 every 10.minutes do
   runner "ApiController.new.mover_productos"
 end
 
 every 10.minutes do
   runner "ApiController.new.mover_productos_pulmon"
 end

 every 5.minutes do
   runner "OrdersController.new.process_order_second_time"
 end

every 15.minutes do
   runner "StoresController.new.abastecer_productos"
 end
