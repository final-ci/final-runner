class FinalAPI
  class Job < FinalAPI
    FINISHED_STATES = %w(passed failed errored canceled)
    FAILED_STATES = %w(failed errored canceled)

    attr_accessor :id

    def self.find(id)
      job = new()
      job.id = id
      job
    end

    def state
      @payload['state']
    end

    def reload!
      response = conn.get("/jobs/#{id}")
      @payload = response.body
      self
    end

    def payload
      reload! if @payload.nil?
      @payload
    end

    def finished?
      FINISHED_STATES.include?(payload['state'])
    end

    def failed?
      FAILED_STATES.include?(payload['state'])
    end

    def wait_for_finish
      while !finished? do
        reload!
        FinalAPI.logger.debug "Current Job state: #{payload['state']}"
        sleep 3
      end
      self
    end

    def logs
      FinalAPI::Log.new(build: self)
    end

  end
end


