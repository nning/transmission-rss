source 'https://rubygems.org'

gemspec

group :test do
  gem 'coveralls', require: false
  gem 'rake'
  gem 'rspec'
  gem 'vcr'
  gem 'webmock'

  # Downgrade to prevent dependency on public_suffix which only works with Ruby
  # 2.0
  gem 'addressable', '~> 2.4.0'
end
