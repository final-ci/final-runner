class FinalAPI
  class Request < FinalAPI
    DEFAULT_TIMEOUT = 60 #in seconds

    attr_accessor :jid_or_id

    def self.create(payload)
      request = new().post(payload)
    end

    def self.find(jid_or_id)
      request = new()
      request.jid_or_id = jid_or_id
      request.reload!
    end

    def id
      @payload && @payload['id']
    end

    def reload!
      @payload = conn.get("/requests/#{jid_or_id}").body
      self
    end

    def post(payload)
      response = conn.post { |req|
        req.url '/requests'
        req.body = MultiJson.dump(payload)
      }
      @jid_or_id = response.body['jid']
      self
    end

    def payload
      self.reload! if @payload.nil?
      @payload
    end

    def finished?
      payload['state'] == 'finished'
    end

    def wait_for_finish
      Timeout.timeout(DEFAULT_TIMEOUT) do
        while !finished? do
          reload!
          FinalAPI.logger.debug "Current request state: #{payload['state']}"
          sleep 3
        end
      end
      self
    end

    def last_build
      wait_for_finish
      build = payload['builds'].last
    end

    def jobs
      last_build['matrix']
    end
  end
end

