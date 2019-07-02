require "NOCH/version"

module NOCH
  
  class Error < StandardError; end
  
  def self.included(base)
    @@alert_name = caller.last.split(".").first
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
  end

  DEFAULT = {
    "status" => "unknown",
    "last_change" => nil,
    "metadata" => nil
  }

  def self.connect!
    @@redis ||= Redis.new
  end

  def self.changed to
    self.connect!
    if (current = @@redis.get(@@alert_name))
      current_status = ::JSON.parse(current)['status']
      current_status if current_status != to
    else
      NOCH.create_object
    end
  end

  def self.evaluate_for what
    raise "Unknown status #{what}" unless ['ok','warning','critial'].include? what
    if (from = self.changed what)
      self.notify from, what, message
      self.set what, message
    end
  end

  def self.create_object
    self.connect!
    @@redis.set @@alert_name, DEFAULT.to_json
  end

  def self.set to, message = nil
    data = {
      'status' => to,
      'last_change' => Time.now,
      'metadata' => message
    }
    @@redis.set @@alert_name, data.to_json
  end

  # notifications
  def self.notify from, to, message
    string = "Alert #{@@alert_name} changed from #{from} to #{to} #{message}"
    self.send_slack(string, self.slack) 
  end

  def self.send_slack message = nil, slack_channel = nil
    if message and slack_channel
      begin
        puts "Enviando: #{message}
        to: #{slack_channel}"
      rescue
        puts "Error sending message to slack channel #{slack_channel}"
      end
    end
  end

  def self.slack
    self.line_for("slack").strip
  end

  def self.line_for what
    line = self.content.select do |line|
      line.start_with? "# #{what.upcase} "
    end.first
    line.split("# #{what.upcase} ").last if line
  end

  def self.content
    @@content ||= IO.read(Dir.pwd + "/" + @@alert_name + ".rb").split("\n")
  end

  # Alert methods
  
  # use to set status to ok
  # @param [String] message (optional) custom message to notify
  def ok! message = nil
    NOCH.evaluate_for "ok"
  end

  # use to set status to warning
  # @param [String] message (optional) custom message to notify
  def warning! message = nil
    NOCH.evaluate_for "warning"
    # if (from = NOCH.changed "warning")
    #   NOCH.notify from, "warning", message
    #   NOCH.set "warning", message
    # end
  end

  # use to set status to critical
  # @param [String] message (optional) custom message to notify
  def critical! message = nil
    NOCH.evaluate_for "critical"
    # if (from = NOCH.changed "critical")
    #   NOCH.notify from, "critical", message
    #   NOCH.set "critical", message
    # end
  end


end
