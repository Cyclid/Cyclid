require 'active_record'
require 'logger'

begin
  ActiveRecord::Base.logger = if defined? Cyclid
                                Cyclid.logger
                              else
                                Logger.new(STDERR)
                              end

  STDERR.puts ENV['RACK_ENV']

  case ENV['RACK_ENV']
  when 'development'
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: 'development.db'
    )
  when 'test'
    Cyclid.logger.info 'In test mode; not creating database connection'
  when 'production'
    Cyclid.logger.error 'No production database'
    abort
  end

rescue StandardError => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
