require 'test/unit'
require 'mocha/test_unit'
require_relative '../../lib/imap_connector'

class ImapConnectorTest < Test::Unit::TestCase
  
  def test_does_not_authenticate_with_invalid_credentials
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').raises(error('authentication failure'))
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    errors = imap_connector.authenticate
    
    assert_equal 'authentication failure', errors.first
  end

  def test_error_appears_if_imap_server_not_reachable
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).raises(SocketError)
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    
    assert_equal 'server not reachable', imap_connector.errors.first
  end


  def test_authenticates_with_valid_credentials
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    response = imap_connector.authenticate

    assert_equal 'OK', response.name
  end

  def test_does_not_return_mails_if_folder_not_exist
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    imap.expects(:select).with('not-existing-folder').raises(error('Mailbox does not exist'))
    imap.expects(:search).never
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    imap_connector.authenticate
    errors = imap_connector.mails_from_folder('not-existing-folder')

    assert_equal 'Mailbox does not exist', errors.first
  end

  def test_does_not_return_mails_if_not_authenticated
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:select).with('inbox').raises(error('Please login first'))
    imap.expects(:search).never
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    errors = imap_connector.mails_from_folder('inbox')

    assert_equal 'Please login first', errors.first
  end

  def test_returns_mails_from_folder
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    imap.expects(:select).with('inbox').returns(ok_response)
    imap.expects(:search).with(['ALL']).returns([1, 2, 3])
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    imap_connector.authenticate

    assert_equal [1, 2, 3], imap_connector.mails_from_folder('inbox')
  end

  def test_error_appears_if_folder_does_not_exist
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    imap.expects(:select).with('not-existing-folder').raises(error('Mailbox does not exist'))
    imap.expects(:search).never
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    imap_connector.authenticate
    errors = imap_connector.youngest_mail_older_than('not-existing-folder', Time.now)

    assert_equal 'Mailbox does not exist', errors.first
  end

  def test_error_appears_if_not_authenticated
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:select).with('inbox').raises(error('Please login first'))
    imap.expects(:search).never
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    errors = imap_connector.youngest_mail_older_than('inbox', Time.now)

    assert_equal 'Please login first', errors.first
  end

  def test_returns_nil_if_youngest_mail_younger_than_date
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    imap.expects(:select).with('inbox').returns(ok_response)
    imap.expects(:search).with(['ALL']).returns([1, 2, 3])
    imap.expects(:fetch).with(3, 'ENVELOPE').returns(fetched_data)
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    imap_connector.authenticate

    time = Time.new(2018, 07, 31, 13)
    assert_equal nil, imap_connector.youngest_mail_older_than('inbox', time)
  end

  def test_returns_date_if_youngest_mail_older_than_date
    imap = mock('imap')
    Net::IMAP.expects(:new).with('hostname.example.com', {port: 143}).returns(imap)
    imap.expects(:authenticate).with('LOGIN', 'bob', '1234').returns(ok_response)
    imap.expects(:select).with('inbox').returns(ok_response)
    imap.expects(:search).with(['ALL']).returns([1, 2, 3])
    imap.expects(:fetch).with(3, 'ENVELOPE').returns(fetched_data)
    
    imap_connector = ImapConnector.new('bob', '1234', 'hostname.example.com')
    imap_connector.authenticate

    time = Time.new(2017, 05, 05, 19)
    assert_equal Time.new(2018, 07, 31, 8), imap_connector.youngest_mail_older_than('inbox', time)
  end
  
  private

  def ok_response
    response = Net::IMAP::TaggedResponse.new
    response.name = 'OK'
    response
  end

  def error(error_message)
    Net::IMAP::NoResponseError.new(bad_response(error_message))
  end

  def bad_response(error_message)
    response = Net::IMAP::TaggedResponse.new
    response.name = 'No'
    text = Net::IMAP::ResponseText.new
    text.text = error_message
    response.data = text
    response
  end

  def fetched_data
    data = Net::IMAP::FetchData.new
    data.attr = {'ENVELOPE' => envelope}
    [data]
  end

  def envelope
    envelope = Net::IMAP::Envelope.new
    envelope.date = "Tue, 31 Jul 2018 08:00:00 +0200"
    envelope
  end
end
