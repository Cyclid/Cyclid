require 'active_record'

begin
  ActiveRecord::Base.logger = Cyclid.logger

  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'test.db'
  )
rescue Exception => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
