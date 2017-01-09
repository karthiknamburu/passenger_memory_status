require "passenger_memory_status/version"
require 'logger'

module PassengerMemoryStatus
  class MemoryStatus

    # Memory in MB
    #
    MEMORY_LIMIT = 500

    def initialize(options = {})
        @memory_limit = options[:memory] || MEMORY_LIMIT
        @logger = Logger.new('passenger_memory_status.log')
    end

    def self.run(options = {})
      new(options).bloated_passenger_process
    end

    # Find and kill the Bloated Passenger Process
    #
    def bloated_passenger_process

      if passenger_installed?

        `passenger-memory-stats`.each_line do |process|

          if process =~ /Passenger RubyApp: /

            pid, pid_memory = getpid(process)
    
            if pid_memory > @memory_limit.to_i

              @logger.info "Found bloated process #{pid} with size #{pid_memory.to_s}"

              sleep 8

              graceful(pid)

              if Process.running?(pid)
                kill(pid)
              end

            end
          end
        end
      else
        @logger.info "The Command `passenger-memory-stats` is not available"
      end

    end

    # Check if the process is running
    #
    def running?(pid)
      return Process.getpid(pid) != -1
    end

    # Graceful kill of passenger process
    #
    def graceful(pid)
        @logger.info "Killing Passenger-Process #{pid} gracefully"
        Process.kill("SIGUSR1", pid)
    end

    # Forceful kill of the process
    #
    def kill(pid)
        @logger.info "Killing Passenger-Process #{pid} forcefully"
        Process.kill("TERM", pid)
    end

    # Get the Process ID from the list
    #
    def getpid(line)
      results = line.split
      pid, pid_memory = results[0].to_i, results[4].to_f
    end

    # Check if Passenger is installed
    #
    def passenger_installed?
      installed_path = `which passenger_memory_status`
      return true unless installed_path.empty?
    end

  end

end
