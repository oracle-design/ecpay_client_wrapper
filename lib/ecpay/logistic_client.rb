# frozen_string_literal: true
require 'net/http'
require 'json'
require 'cgi'
require 'digest'
require 'ecpay/errors'
require 'ecpay/helpers'
require 'ecpay/core_ext/hash'

module Ecpay
  class LogisticClient # :nodoc:
    include Ecpay::Helpers

    EXPRESS_CREATE_API_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/Create',
      production: 'https://logistics.ecpay.com.tw/Express/Create'
    }.freeze

    EXPRESS_MAP_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/map',
      production: 'https://logistics.ecpay.com.tw/Express/map'
    }.freeze

    B2C_TEST_OPTIONS = {
      merchant_id: '2000132',
      hash_key: '5294y06JbISpM5x9',
      hash_iv: 'v77hoKGq4kWxNNIS'
    }.freeze

    C2C_TEST_OPTIONS = {
      merchant_id: '2000933',
      hash_key: 'XBERn1YOvpM9nfZc',
      hash_iv: 'h1ONHk4P4yqbl5LK'
    }.freeze

    attr_reader :options

    def initialize(options = {})
      @options = { mode: :production,
                   hexdigest_type: :md5 }.merge!(options)

      case @options[:mode]
      when :production
        option_required! :merchant_id, :hash_key, :hash_iv
      when :test
        case @options[:logistics_sub_type].try(:to_sym)
        when :FAMI, :UNIMART, :HILIFE, :TCAT, :ECAN
          @options.merge!(B2C_TEST_OPTIONS)
        when :FAMIC2C, :UNIMARTC2C, :HILIFEC2C
          @options.merge!(C2C_TEST_OPTIONS)
        else
          raise InvalidLogisticSubType, %(option :logistics_sub_type is not in option list please check document https://www.ecpay.com.tw/Content/files/ecpay_030.pdf)
        end
      else
        raise InvalidMode, %(option :mode is either :test or :production)
      end

      @options.freeze
    end

    def generate_checkout_params(overwrite_params = {})
      generate_params({
        MerchantTradeNo: SecureRandom.hex(4),
        MerchantTradeDate: Time.current.strftime('%Y/%m/%d %H:%M:%S'),
        PaymentType: 'aio',
        EncryptType: 1
      }.merge!(overwrite_params))
    end

    # def query_trade_info(merchant_trade_number, platform = nil)
    #   params = {
    #     MerchantTradeNo: merchant_trade_number,
    #     TimeStamp: Time.current.to_i,
    #     PlatformID: platform
    #   }
    #   params.delete_if { |_k, v| v.nil? }

    #   post_params = generate_params(params)

    #   res = request(:query_trade_info, post_params)

    #   parse_request_body_to_hash(res)
    # end

    # def query_credit_card_period_info(merchant_trade_number)
    #   params = {
    #     MerchantTradeNo: merchant_trade_number,
    #     TimeStamp: Time.current.to_i
    #   }
    #   post_params = generate_params(params)

    #   res = request(:query_credit_card_period_info, post_params)

    #   JSON.parse(res.body)
    # end

    # private

    # def request(type, params = {})
    #   case type
    #   when :query_trade_info
    #     api_url = EXPRESS_CREATE_API_END_POINTS[@options[:mode]]
    #   when :query_credit_card_period_info
    #     api_url = EXPRESS_MAP_END_POINT[@options[:mode]]
    #   end

    #   Net::HTTP.post_form URI(api_url), post_params
    # end
  end
end
