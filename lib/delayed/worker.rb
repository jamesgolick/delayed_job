module Delayed
  class Worker
    SLEEP = 5
    attr_reader :pid_file

    def initialize(options={})
      @quiet = options[:quiet]
      Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
      @pid_file = options[:pid_file]
    end                                                                          

    def start
      say "*** Starting job worker #{Delayed::Job.worker_name}"

      worker = self
      trap('TERM') { say 'Exiting...'; worker.cleanup_pid_file; $exit = true }
      trap('INT')  { say 'Exiting...'; worker.cleanup_pid_file; $exit = true }

      loop do
        result = nil

        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end

        count = result.sum

        break if $exit

        if count.zero?
          sleep(SLEEP)
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        break if $exit
      end
    end
    
    def say(text)
      puts text unless @quiet
      RAILS_DEFAULT_LOGGER.info text
    end

    protected
      def cleanup_pid_file
        File.delete(pid_file) if !pid_file.nil? && File.exists?(pid_file)
      end
  end
end

