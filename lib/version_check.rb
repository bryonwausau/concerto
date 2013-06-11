# Check the latest version of Concerto 2 via remote sources.
module VersionCheck

  REMOTE_URL = 'http://dl.concerto-signage.org/version.txt'
  GITHUB_URL = 'https://api.github.com/repos/concerto/concerto/git/refs/tags'

  # Find the latest version of Concerto available..
  # First hit the Concerto team's version information, if that is unavailable head directly
  # to Github and try to find the latest tag.  If all else fails return nil.
  # @return [String, nil] String with the latest version, if available.
  def self.latest_version
    version = remote_version()
    if version.nil?
      version = github_version()
    end
    return version
  end

private  # This doesn't actually work, we have to use private_class_method for class methods.

  def self.remote_version
    require 'open-uri'
    version = nil
    begin
      file = open(VersionCheck::REMOTE_URL)
      version = file.read.chomp!
    rescue => e
      Rails.logger.error("Could not determine version number at remote location #{e.message}")
    end
    return version
  end
  private_class_method :remote_version

  def self.github_version
    require 'net/https'
    require 'uri'
    require 'json'

    begin
      uri = URI.parse(VersionCheck::GITHUB_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https" # enable SSL/TLS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = Rails.root.join('config', 'cacert.pem').to_s
      end
      http.start {
        http.request_get(uri.path) do |res|
          versions = []
          begin
            JSON.parse(res.body).each do |tag|
              versions << tag['ref'].gsub(/refs\/tags\//,'')
            end
          rescue => e
            Rails.logger.error("Unable to parse github version feed: #{e.message}.")
          end
          versions.sort! {|x,y| y <=> x }
          if !versions.empty?
            return versions[0]
          else
            return nil
          end
        end
      }
    rescue => e # if for any reason we cannot determine the version then return an error condition
      logger.error("Could not determine version number at github location #{e.message}")
      return nil
    end
  end
  private_class_method :github_version

end