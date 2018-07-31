require 'net/imap'

class ImapConnector
  attr_reader :errors

  def initialize(username, password, hostname, port: 143, ssl: false)
    @username = username
    @password = password
    @errors = []
    @imap = Net::IMAP.new(hostname, {port: port})
    imap.starttls({}, true) if ssl
  rescue SocketError
    errors << 'server not reachable'
  end

  def authenticate
    imap.authenticate('LOGIN', username, password)
  rescue Net::IMAP::Error => error
    errors << error.message 
  end

  def mails_from_folder(foldername)
    imap.select(foldername)
    imap.search(['ALL'])
  rescue Net::IMAP::Error => error
    errors << error.message 
  end

  def youngest_mail_older_than(foldername, date)
    imap.select(foldername)
    id = imap.search(['ALL']).last
    youngest_mail_date = Time.parse(imap.fetch(id, 'ENVELOPE').first.attr['ENVELOPE'].date)

    youngest_mail_date > date ? youngest_mail_date : nil
  rescue Net::IMAP::Error => error
    errors << error.message 
  end

  private

  attr_reader :username, :password, :imap
end
