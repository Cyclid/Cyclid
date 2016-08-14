Gem::Specification.new do |s|
  s.name        = 'cyclid'
  s.version     = '0.2.0'
  s.licenses    = ['Apache-2.0']
  s.summary     = 'Cyclid CI API'
  s.description = 'The Cyclid CI system'
  s.authors     = ['Kristian Van Der Vliet']
  s.homepage    = 'https://cyclid.io'
  s.email       = 'contact@cyclid.io'
  s.files       = Dir.glob('app/**/*') +
                  Dir.glob('lib/**/*') +
                  Dir.glob('bin/*') +
                  %w(db/schema.rb LICENSE README.md)
  s.bindir      = 'bin'
  s.executables << 'cyclid-db-init'

  s.add_runtime_dependency('oj', '~> 2.14')
  s.add_runtime_dependency('require_all', '~> 1.3')
  s.add_runtime_dependency('sinatra', '~> 1.4')
  s.add_runtime_dependency('sinatra-contrib', '~> 1.4')
  s.add_runtime_dependency('sinatra-cross_origin', '~> 0.3')
  s.add_runtime_dependency('warden', '~> 1.2')
  s.add_runtime_dependency('activerecord', '~> 4.2')
  s.add_runtime_dependency('sinatra-activerecord', '~> 2.0')
  s.add_runtime_dependency('bcrypt', '~> 3.1')
  s.add_runtime_dependency('net-ssh', '~> 3.1')
  s.add_runtime_dependency('net-scp', '~> 1.2')
  s.add_runtime_dependency('sidekiq', '~> 4.1')
  s.add_runtime_dependency('mysql', '~> 2.9')
  s.add_runtime_dependency('slack-notifier', '~> 1.5')
  s.add_runtime_dependency('mail', '~> 2.6')
  s.add_runtime_dependency('premailer', '~> 1.8')
  s.add_runtime_dependency('hpricot', '~> 0.8')
  s.add_runtime_dependency('jwt', '~> 1.5')

  s.add_runtime_dependency('cyclid-core', '~> 0')
  s.add_runtime_dependency('mist-client', '~> 0')
end
