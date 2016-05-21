# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

#crontab -l
#whenever --update-crontab
set :environment, "development"
#"production"
set :output, {:error => "#{path}/log/cron_error.log", :standard => "#{path}/log/cron.log"}

#set :output, "#{path}/log/cron.log"

#job_type :runner, "{ cd #{@current_path} > /dev/null; } && RAILS_ENV='production' bundle exec rails runner ':task' :output"
#job_type :runner, "cd #{@path} && RAILS_ENV='production' /home/jddm11/.rvm/wrappers/ruby-2.3.1/bundle exec rails runner ':task' :output"


 every 12.hours do
   runner "OrdersController.new.get_orders_by_ftp1"
 end

 every 5.minutes do
   runner "OrdersController.new.process_order_first_time1"
 end

<<<<<<< HEAD
 every 5.minutes do
   runner "ApiController.new.mover_productos"
 end
 
 every 5.minutes do
   runner "ApiController.new.mover_productos_pulmon"
=======
 every 10.minutes do
   runner "ApiController.new.mover_productos1"
>>>>>>> ab9de1ba73033e08cb9df9751072eaf3663cc273
 end

 every 1.hour do
   runner "OrdersController.new.process_order_second_time1"
 end

every 15.minutes do
   runner "StoresController.new.abastecer_productos1"
 end

