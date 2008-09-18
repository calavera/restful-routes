module RestfulRoutes

  LOG_LEVELS = {:debug => 1, :info => 2, :error => 3}

  class Logger

    def debug(message)
      puts "[DEBUG] #{message}" if debug?
    end

    def info(message)
      puts "[INFO] #{message}" if info?
    end

    def error(message)
      puts "[ERROR] #{message}"
    end

    def debug?
      RestfulRoutes::LOG_LEVEL <= RestfulRoutes::LOG_LEVELS[:debug]
    end

    def info?
      RestfulRoutes::LOG_LEVEL <= RestfulRoutes::LOG_LEVELS[:info]
    end
  end
end
