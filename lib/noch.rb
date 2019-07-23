require "NOCH/version"
require 'slack-ruby-client'
require 'redis'
require 'telegram/bot'

module NOCH
  
  class Error < StandardError; end

  class << self
    # Sets default status. Used the first time execution with passed status
    # @param [String] to: the status to be saved
    # @return [Hash]
    def default to, data = nil
      {
        "status" => to,
        "data" => data
      }
    end
    
    def included(base)
      @@alert_file = caller.select{|l| l.include? "`include'"}.first.split(".").first
      @@alert_name = @@alert_file.split('/').last.split('_').map{|w| w.capitalize}.join(" ")
      @@redis_host = ENV['REDIS_HOST'] || 'localhost'
      @@redis_port = ENV['REDIS_PORT'] || '6379'
      @@redis ||= ::Redis.new(host: @@redis_host, port: @@redis_port)
      @@slack_client = if ENV['SLACK_API_TOKEN']
        ::Slack.configure do |config|
          config.token = ENV['SLACK_API_TOKEN']
        end
        ::Slack::Web::Client.new
      end
      @@telegram_client = if ENV['TELEGRAM_TOKEN'] and ENV['TELEGRAM_USER']
        ::Telegram::Bot::Client.new(ENV['TELEGRAM_TOKEN'], ENV['TELEGRAM_USER'])
      end
    end

    # Returns the name of the alert
    def alert_name
      @@alert_name
    end

    # Returns the current status if the passed status is differente. If there is no current status save passed status with default data
    # @param [String] to: the status to be evaluated
    # @return [String] status: if passed value is different
    # @return [Hash] Data: data to be saved
    def changed to, data
      if (current = self.get_status)
        current_status = ::JSON.parse(current)['status']
        return current_status if current_status != to
        to
      else
        NOCH.create_object(to, data)
      end
    end

    # Returns the current status of the alert
    # @return [Hash] {"status"=>"ok", "last_change"=>"2019-07-17T22:51:03.081-03:00", "message"=>nil, "data"=>nil}
    def get_status
      @@redis.get(@@alert_name)
    end

    # Sends notification if status change. If not returns nil
    # @param [String] what: current status
    # @param [optional] opts: The arguments. Could be String for only message text or a Hash to pass :message and :data
    # @return [Boolean] true if notification is sent, false if nothing changed
    # def evaluate_for what, message = nil, data = nil
    def evaluate_for what, opts = nil
      if opts.is_a? Hash
        message = opts.delete(:message)
        data = opts.delete(:data)
      else
        message = opts
      end
      raise "Unknown status #{what}. Allowed: ['ok','warning','critical','skip']" unless ['ok','warning','critical','skip'].include? what
      from = self.changed(what, data)
      !!(if (from != what)
          self.set what, message, data
          self.notify(from, what, message, data) unless what == 'skip'
      end)
    end

    # Saves into Redis the alert with `to` as initial status
    # @param [String] to: the value of the status to be saved
    # @param [Hash] data: the data to be saved
    def create_object(to, data)
      return to if @@redis.set(@@alert_name, self.default(to, data).to_json) == "OK"
      raise StandardError.new("Status `#{to}` could not be saved")
    end

    # Saves status, message and data into Redis
    # @param [String] to: status to save. It could be ['ok','warning','skip','critical']
    # @param [String] message (optional): The message to be sent on notification
    # @param [Hash] data(optional): data to be saved for future evaluation if needed
    def set to, message = nil, data = nil
      data = {
        'status' => to,
        'last_change' => Time.now,
        'message' => message,
        'data' => data
      }
      @@redis.set @@alert_name, data.to_json
    end

    # Prints out notification information and sends it
    # @param [String] from: the previous status
    # @param [Strig] to: the current status
    # @param [Hash] data (optional): the data to be saved
    # @return [Boolean] true if notification sent. false if not
    def notify from, to, message, data = nil
      string = "Alert: #{@@alert_name}

[ #{from} ] => [ #{to} ]
      
#{message}
      
      "
      string += "
      
      Data: 
      #{data}
      " if data
      print string
      self.send_slack(string)
      self.send_telegram(string)
    end

    # Sends message notification through Slack to the given slack channel
    # @param [String] message: the message string to be sent
    # @return [Boolean] true if notification sent. false if not
    def send_slack message = nil
      channel = self.slack
      if channel and !!@@slack_client
        @@slack_client.auth_test
        if message
          begin
            puts "Enviando: #{message}
            to: #{channel}"
            @@slack_client.chat_postMessage(channel: channel, text: message, as_user: true)
            true
          rescue
            puts "Error sending message to slack channel #{channel}"
            false
          end
        end
      end
    end

    # Returns value for slack token
    def slack
      self.matched_line("SLACK")&.strip
    end

    # Sends message notification through Slack to the given slack channel
    # @param [String] message: the message string to be sent
    # @return [Boolean] true if notification sent. false if not
    def send_telegram message = nil
      chat_id = self.telegram
      if chat_id and !!@@telegram_client
        if message
          begin
            puts "Enviando: #{message}
            to: #{chat_id}"
            @@telegram_client.send_message(chat_id: chat_id, text: message)
            true
          rescue
            puts "Error sending message to telegram group #{group_id}"
            false
          end
        end
      end
    end

    # Returns value for telegram group id
    def telegram
      self.matched_line("TELEGRAM")&.strip
    end  

    # To get config token and/or values, e.g for slack, returns values from line containing arg
    # @return [String] value for line staring with `# <something> `
    # @param [String] what = configuration name. E.g. 
    #
    #   # SLACK 1234567890987654321
    #
    # will return 1234567890987654321 when param what is SLACK
    #
    def matched_line what
      line = self.content.select do |line|
        line.start_with? "# #{what} "
      end.first
      line.split("# #{what.upcase} ").last if line
    end

    def content
      @@content ||= IO.read(@@alert_file + ".rb").split("\n")
    end
  end

  # Alert methods
  
  # use to set status to ok
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def ok! opts = nil
    NOCH.evaluate_for "ok", opts
  end

  # use to set status to warning
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def warning! opts = nil
    NOCH.evaluate_for "warning", opts
  end

  # use to set status to critical
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def critical! opts = nil
    NOCH.evaluate_for "critical", opts
  end

  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def skip! opts = nil
    NOCH.evaluate_for "skip", opts
  end

  # Returns the current status. Useful when you save aditional data into status
  # @return [Hash] {"status"=>"ok", "last_change"=>"2019-07-17T22:51:03.081-03:00", "message"=>nil, "data"=>nil}
  def get_current
    JSON.parse(NOCH.get_status)
  end

  # Returns the last data saved
  # @return [String] last data saved
  def last_data
    get_current['data']
  end

  def alert_name
    @@alert_name
  end

  def inspect
    {
      "version" => VERSION,
      "alert_name" => @@alert_name
    }
  end

end
