require 'net/http'
require 'openssl'
require 'json'
require 'cgi'
require 'digest'
require 'ecpay/errors'
require 'ecpay/helpers'
require 'ecpay/core_ext/hash'

module Ecpay
  class InvoiceClient # :nodoc:
    include Ecpay::Helpers

    INVOICE_ISSUE_API_ENDPOINTS = {
      test: 'https://einvoice-stage.ecpay.com.tw/Invoice/Issue',
      production: 'https://einvoice.ecpay.com.tw/Invoice/Issue'
    }.freeze
    INVOICE_INVALID_API_ENDPOINTS = {
      test: 'https://einvoice-stage.ecpay.com.tw/Invoice/IssueInvalid',
      production: 'https://einvoice.ecpay.com.tw/Invoice/IssueInvalid'
    }.freeze
    ALLOWANCE_ISSUE_API_ENDPOINTS = {
      test: 'https://einvoice-stage.ecpay.com.tw/Invoice/Allowance',
      production: 'https://einvoice.ecpay.com.tw/Invoice/Allowance'
    }.freeze
    INVOICE_SEARCH_API_ENDPOINTS = {
      test: 'https://einvoice-stage.ecpay.com.tw/Query/Issue',
      production: 'https://einvoice.ecpay.com.tw/Query/Issue'
    }.freeze

    TEST_OPTIONS = {
      merchant_id: '2000132',
      hash_key: 'ejCk326UnaZWKisg',
      hash_iv: 'q9jcZX8Ib9LM8wYk'
    }.freeze

    SPECIAL_ENCODE_KEYS = %i[CustomerName CustomerAddr CustomerEmail NotifyMail InvoiceRemark ItemName ItemWord ItemRemark].freeze
    SKIP_CHECK_MAC_KEYS = %i[ItemRemark InvoiceRemark PosBarCode ItemName ItemWord QRCode_Left QRCode_Right].freeze

    attr_reader :options

    def initialize(options = {})
      @options = { mode: :production,
                   hexdigest_type: :md5 }.merge!(options)

      case @options[:mode]
      when :production
        option_required! :merchant_id, :hash_key, :hash_iv
      when :test
        @options.merge!(TEST_OPTIONS)
      else
        raise InvalidMode, %(option :mode is either :test or :production)
      end

      @options.freeze
    end

    def invoice_issue(params = {})
      param_required! params, %i[
        RelateNumber
        Print
        Donation
        TaxType
        SalesAmount
        ItemName
        ItemCount
        ItemWord
        ItemPrice
        ItemAmount
        InvType
      ]

      # notes:
      # ItemName > 名稱 1|名稱 2|名稱 3
      # ItemCount > 1|2|3
      # ItemWord > 名稱 1|名稱 2|名稱 3
      # ItemPrice > 44|55|66
      # ItemAmount > 100|100|100|

      # accept params:
      # CustomerID
      # CustomerIdentifier
      # CustomerName > #convert_to_dot_net(url_encoded)
      # CustomerAddr > #convert_to_dot_net(url_encoded)
      # CarruerNum
      # InvoiceRemark > #convert_to_dot_net(url_encoded)
      # vat

      # when param has certain value then must have the following one
      # Donation = 1 > CarruerType*
      # Print = 0 > LoveCode*
      # TaxType = 9 > ItemTaxType

      # must have either one:
      # CustomerPhone || CustomerEmail

      post_params = {
        TimeStamp: Time.now.to_i
      }.merge!(params)

      post_params.delete_if { |_key, value| value.nil? }

      res = request :invoice_issue, post_params

      parse_request_body_to_hash(res, decode_keys: [:RtnMsg])
    end

    def invoice_invalid(params = {})
      param_required! params, %i[
        InvoiceNumber
        Reason
      ]

      # notes:
      # Reason > #convert_to_dot_net(url_encoded)

      post_params = {
        TimeStamp: Time.now.to_i
      }.merge!(params)

      post_params.delete_if { |_key, value| value.nil? }

      res = request :invoice_invalid, post_params

      parse_request_body_to_hash(res, decode_keys: [:RtnMsg])
    end

    def allowance_issue(params = {})
      param_required! params, %i[
        InvoiceNo
        AllowanceNotify
        AllowanceAmount
        ItemName
        ItemCount
        ItemWord
        ItemPrice
        ItemAmount
      ]

      # accept params:
      # CustomerName > #convert_to_dot_net(url_encoded)
      # NotifyMail > #convert_to_dot_net(url_encoded)
      # NotifyPhone
      # ItemTaxType

      post_params = {
        TimeStamp: Time.now.to_i
      }.merge!(params)

      post_params.delete_if { |_key, value| value.nil? }

      res = request :allowance_issue, post_params

      parse_request_body_to_hash(res, decode_keys: [:RtnMsg])
    end

    def invoice_search_by_merchant_order_no(params = {})
      param_required! params, %i[
        RelateNumber
      ]

      post_params = {
        TimeStamp: Time.now.to_i
      }.merge!(params)

      post_params.delete_if { |_key, value| value.nil? }

      res = request :invoice_search, post_params

      check_mac_params = parse_request_body_to_hash(res).reject do |key, _v|
        SKIP_CHECK_MAC_KEYS.include?(key.to_sym)
      end

      raise CheckMacError, 'Not valid mac value' unless verify_mac(check_mac_params)

      parse_request_body_to_hash(res, decode_keys: %i[RtnMsg QRCode_Left QRCode_Right IIS_Customer_Name IIS_Customer_Addr ItemName ItemWord InvoiceRemark])
    end

    private

    def request(type, params = {})
      mode = @options[:mode]
      params_skip_chech_mac = {}

      case type
      when :invoice_issue
        api_url = INVOICE_ISSUE_API_ENDPOINTS[mode]
      when :invoice_invalid
        api_url = INVOICE_INVALID_API_ENDPOINTS[mode]
      when :allowance_issue
        api_url = ALLOWANCE_ISSUE_API_ENDPOINTS[mode]
      when :invoice_search
        api_url = INVOICE_SEARCH_API_ENDPOINTS[mode]
      end

      SPECIAL_ENCODE_KEYS.each do |key|
        next if !params[key]
        params[key] = CGI.escape(params[key])
        params[key].downcase!
        convert_to_dot_net(params[key])
      end

      SKIP_CHECK_MAC_KEYS.each do |key|
        params_skip_chech_mac[key] = params.delete(key)
      end

      post_params = generate_params(params)
      post_params.merge!(params_skip_chech_mac)

      SPECIAL_ENCODE_KEYS.each do |key|
        next if !post_params[key]
        post_params[key] = CGI::unescape(post_params[key])
      end

      Net::HTTP.post_form URI(api_url), post_params
    end
  end
end
