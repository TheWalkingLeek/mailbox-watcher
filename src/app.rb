require 'yaml'
require 'sinatra'
require_relative 'lib/imap_connector'

class App < Sinatra::Base

  # start server: puma

  get '/test-config' do
    config = YAML.load_file('config/cryptopus.yml')
    imap_connector = ImapConnector.new('username', 'password', 'hostname.hallo.ch', ssl: true)
    imap_connector.authenticate
    return 200, config['description']
  end
end
