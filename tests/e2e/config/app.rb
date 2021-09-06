#!/usr/bin/env ruby
# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'rexml/document'
require 'colorized_string'

$stdout.sync = true
$messages = 0

require 'bundler/setup' # Set up gems listed in the Gemfile.
Bundler.require(:default)
require 'sidekiq/api'
require_relative '../app/some_worker'

url = 'redis://redis/5'

Sidekiq.configure_server do |conf|
  conf.redis = { url: url }
end

Sidekiq.configure_client do |conf|
  conf.redis = { url: url }
end
