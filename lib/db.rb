require 'active_record'
require 'logger'

begin
  if defined? Cyclid
    ActiveRecord::Base.logger = Cyclid.logger
  else
    ActiveRecord::Base.logger = Logger.new(STDERR)
  end

  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'test.db'
  )
rescue Exception => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
