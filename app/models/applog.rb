class Applog
  def self.debug(message=nil,from=nil)
    @my_log ||= Logger.new("#{Rails.root}/log/process_#{DateTime.now.strftime('%m-%d-%Y').to_s}.log")
    @my_log.debug(from) unless from.nil?
    @my_log.debug(message) unless message.nil?
  end
end
