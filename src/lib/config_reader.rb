require 'yaml'

class ConfigReader
  attr_reader :projectname, :errors
  
  def initialize(projectname)
    @projectname = projectname
    @errors = []
  end

  def project_description
  end

  def mailbox_description(mailboxname)
  end

  def folder_description(mailboxname, foldername)
  end

  def alert_regex(mailboxname, foldername)
  end
  
  def max_age(mailboxname, foldername)
  end

  def imap_config(mailboxname)
  end

  # private

  def validate_config_file
    file_exists?
    require 'pry'; binding.pry
  rescue RuntimeError => error
    errors << error.message
    require 'pry'; binding.pry
  end

  def validate_secret_file
  end

  private

  def file_exists?
    filename = 'config/' + projectname + '.yml'

    unless File.exists?(filename)
      raise 'Config-File ' + filename + ' does not exist'
    end
  end
end
