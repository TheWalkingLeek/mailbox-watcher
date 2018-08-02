require 'yaml'
require 'sinatra'
require 'i18n'
require_relative 'lib/imap_connector'
require_relative 'lib/config_reader'

class App < Sinatra::Base

  # start server: puma

  get '/test-config' do
    config = YAML.load_file('config/cryptopus.yml')
    require 'pry'; binding.pry
    I18n.load_path = Dir['config/locales/en.yml']
    # I18n.backend.load_translations
    I18n.t(:test)
    imap_connector = ImapConnector.new('username', 'password', 'hostname.hallo.ch', ssl: true)
    imap_connector.authenticate
    return 200, config['description']
  end
end
