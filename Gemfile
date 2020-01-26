source 'https://rubygems.org'

gemspec

if ENV['ROM_CORE_FROM_MASTER'].eql?('true')
  gem 'rom-core', git: 'https://github.com/rom-rb/rom.git', branch: 'master'
end

if ENV['DRY_TYPES_FROM_MASTER'].eql?('true')
  gem 'dry-types', git: 'https://github.com/dry-rb/dry-types.git', branch: 'master'
end

if ENV['SEQUEL_FROM_MASTER'].eql?('true')
  gem 'sequel', git: 'https://github.com/jeremyevans/sequel.git', branch: 'master'
end

group :test do
  gem 'codacy-coverage', require: false
  gem 'pry-byebug', platforms: :mri
  gem 'pry', platforms: :jruby
  gem 'activesupport', '~> 5.0'
  gem 'simplecov', require: false
  gem 'pg', '~> 1.1', platforms: :mri
  gem 'mysql2', platforms: :mri
  gem 'jdbc-postgres', '>= 9.4.1212', platforms: :jruby
  gem 'jdbc-mysql', platforms: :jruby
  gem 'sqlite3', platforms: :mri
  gem 'jdbc-sqlite3', platforms: :jruby
  gem 'ruby-oci8', platforms: :mri if ENV['ROM_USE_ORACLE']
  gem 'warning'
end
