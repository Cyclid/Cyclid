require 'active_record'
require 'logger'

begin
  ActiveRecord::Base.logger = if defined? Cyclid
                                Cyclid.logger
                              else
                                Logger.new(STDERR)
                              end

  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'test.db'
  )
rescue StandardError => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
