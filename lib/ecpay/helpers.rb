module Ecpay
  module Helpers
    def generate_params(overwrite_params = {})
      result = overwrite_params.clone
      result[:MerchantID] = @options[:merchant_id]
      result[:CheckMacValue] = make_mac(result)
      result
    end

    def make_mac(params = {})
      raw = params.sort_by { |k, _v| k.downcase }.map! { |k, v| "#{k}=#{v}" }.join('&')
      padded = "HashKey=#{@options[:hash_key]}&#{raw}&HashIV=#{@options[:hash_iv]}"
      url_encoded = CGI.escape(padded).downcase!

      convert_to_dot_net(url_encoded)

      case @options[:hexdigest_type]
      when :md5
        Digest::MD5.hexdigest(url_encoded).upcase!
      when :sha256
        Digest::SHA256.hexdigest(url_encoded).upcase!
      end
    end

    def verify_mac(params = {})
      stringified_keys = params.stringify_keys
      check_mac_value = stringified_keys.delete('CheckMacValue')
      make_mac(stringified_keys) == check_mac_value
    end

    private

    def parse_request_body_to_hash(res)
      Hash[res.body.split('&').map! { |i| i.split('=') }]
    end

    def option_required!(*option_names)
      option_names.each do |option_name|
        raise MissingOption, %(option "#{option_name}" is required.) if @options[option_name].nil?
      end
    end

    def param_required!(params, param_names)
      param_names.each do |param_name|
        raise MissingParameter, %(param "#{param_name}" is required.) if params[param_name].nil?
      end
    end

    def convert_to_dot_net(url_encoded)
      url_encoded.gsub!('%2d', '-')
      url_encoded.gsub!('%5f', '_')
      url_encoded.gsub!('%2e', '.')
      url_encoded.gsub!('%21', '!')
      url_encoded.gsub!('%2a', '*')
      url_encoded.gsub!('%28', '(')
      url_encoded.gsub!('%29', ')')
    end
  end
end
