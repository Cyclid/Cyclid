require 'active_record'
require 'logger'

begin
  case ENV['RACK_ENV']
  when 'development'
    database = if defined? Cyclid
                 Cyclid.config.database
               else
                 'sqlite3:development.db'
               end

    ActiveRecord::Base.establish_connection(
      database
    )

    ActiveRecord::Base.logger = if defined? Cyclid
                                  Cyclid.logger
                                else
                                  Logger.new(STDERR)
                                end
  when 'production'
    ActiveRecord::Base.establish_connection(
      Cyclid.config.database
    )

    ActiveRecord::Base.logger = Cyclid.logger
  when 'test'
    Cyclid.logger.info 'In test mode; not creating database connection'
  end

rescue StandardError => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
