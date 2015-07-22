class FinalAPI
  class Log < FinalAPI
    attr_reader :build, :last_number, :final

    def initialize(build:)
      @build = build
      @last_number = 0
      @final = false
    end

    def logs
      params = {}
      params[:after] = last_number
      response = conn.get("/jobs/#{@build.id}/logs", params )
      @payload = response.body
      self
    end

    def parts
      logs
      @payload and @payload['parts']
    end

    def archived?
      @payload and @payload['archived_at']
    end

    def finished?
      build.reload! unless build.finished?
      build.finished? and @final or archived?
    end

    def read_logs
      current_parts = parts
      while(
        Array === current_parts and
        (first_part = current_parts.shift) and
        (first_part['number'] == @last_number + 1)
      ) do
        FinalAPI.logger.debug "LOG[#{last_number}]: #{first_part.inspect}"
        yield first_part['content'], @last_number
        @last_number += 1
        @final = first_part['final']
      end
    end

  end
end

