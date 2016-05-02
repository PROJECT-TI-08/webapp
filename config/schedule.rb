# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

#crontab -l
#whenever --update-crontab
set :environment, "development"
#set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#

 every 2.minutes do
   runner "OrdersController.new.run_oc"
 end

# Learn more: http://github.com/javan/whenever
