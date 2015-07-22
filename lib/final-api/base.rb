class FinalAPI

  attr_accessor :conn

  class << self
    def logger
      @logger ||= begin
        l = Logger.new(STDOUT)
        l.level = Logger::WARN
        l
      end
    end

    def logger=(l)
      @logger = l
    end

    def base_url
      @base_url
    end

    def base_url=(url)
      @base_url = url
    end
  end

  def conn
    @conn ||= Faraday.new(url: base_url) do |faraday|
      faraday.headers['UserName'] = 'FIN'
      faraday.headers['AuthenticationToken'] = 'secret'
      faraday.headers['Content-Type'] = 'application/json'
      faraday.headers['Accept'] = 'application/json'
      faraday.request :json
      faraday.response :json, :content_type => /\bjson$/
      #faraday.response :logger
      faraday.use :instrumentation
      faraday.adapter Faraday.default_adapter
    end
  end

  def logger
    self.class.logger
  end

  def base_url
    @base_url ||= FinalAPI.base_url
  end

end


