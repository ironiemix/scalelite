# frozen_string_literal: true

require 'net/http'

module ApiHelper
  extend ActiveSupport::Concern
  include BBBErrors

  REQUEST_TIMEOUT = 10

  # Encode URI and append checksum
  def encode_bbb_uri(action, base_uri, secret, bbb_params)
    check_string = URI.encode_www_form(bbb_params)
    checksum = Digest::SHA1.hexdigest(action + check_string + secret)
    uri = URI.join(base_uri, action)
    uri.query = URI.encode_www_form(bbb_params.merge(checksum: checksum))
    uri
  end

  # Get request
  def get_req(uri)
    req = Net::HTTP::Get.new(uri.request_uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                        open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      res = http.request(req)
      doc = Nokogiri::XML(res.body)
      if doc.at_xpath('/response/returncode').content != 'SUCCESS'
        raise BBBError.new(doc.at_xpath('/response/messageKey').content, doc.at_xpath('/response/message').content)
      end

      doc
    end
  end
end
