# frozen_string_literal: true

require 'net/http'
require 'json'
require 'cgi'
require 'digest'
require 'ecpay/errors'
require 'ecpay/helpers'
require 'ecpay/core_ext/hash'

module Ecpay
  class Client # :nodoc:
    include Ecpay::Helpers

    CHECKOUT_END_POINTS = {
      test: 'https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5',
      production: 'https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5'
    }.freeze

    QUERY_TRADE_INFO_API_ENDPOINTS = {
      test: 'https://payment-stage.ecpay.com.tw/Cashier/QueryTradeInfo/V5',
      production: 'https://payment.ecpay.com.tw/Cashier/QueryTradeInfo/V5'
    }.freeze

    QUERY_CC_TRADE_INFO_API_ENDPOINTS = {
      test: nil,
      production: 'https://payment.ecpay.com.tw/CreditDetail/QueryTrade/V2'
    }.freeze

    QUERY_CREDIT_CARD_PERIOD_INFO_API_ENDPOINTS = {
      test: 'https://payment-stage.ecpay.com.tw/Cashier/QueryCreditCardPeriodInfo',
      production: 'https://payment.ecpay.com.tw/Cashier/QueryCreditCardPeriodInfo'
    }.freeze

    CREDIT_DETAIL_DO_ACTION_API_ENDPOINTS = {
      test: nil,
      production: 'https://payment.ecpay.com.tw/CreditDetail/DoAction'
    }.freeze

    TEST_OPTIONS = {
      merchant_id: '2000132',
      hash_key: '5294y06JbISpM5x9',
      hash_iv: 'v77hoKGq4kWxNNIS'
    }.freeze

    attr_reader :options

    def initialize(options = {})
      @options = { mode: :production,
                   hexdigest_type: :sha256 }.merge!(options)

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

    def generate_checkout_params(overwrite_params = {})
      generate_params({
        MerchantTradeNo: SecureRandom.hex(4),
        MerchantTradeDate: Time.current.strftime('%Y/%m/%d %H:%M:%S'),
        PaymentType: 'aio',
        EncryptType: 1
      }.merge!(overwrite_params))
    end

    def query_trade_info(merchant_trade_number, platform = nil)
      params = {
        MerchantTradeNo: merchant_trade_number,
        TimeStamp: Time.current.to_i,
        PlatformID: platform
      }.compact

      post_params = generate_params(params)

      res = request(:query_trade_info, post_params)

      parse_request_body_to_hash(res)
    end

    def query_cc_trade_info(credit_refund_id:, credit_amount:, credit_check_code:)
      params = {
        CreditRefundId: credit_refund_id,
        CreditAmount: credit_amount,
        CreditCheckCode: credit_check_code
      }.compact

      post_params = generate_params(params)

      res = request(:query_trade_info, post_params)

      parse_request_body_to_hash(res)
    end

    def query_credit_card_period_info(merchant_trade_number)
      params = {
        MerchantTradeNo: merchant_trade_number,
        TimeStamp: Time.current.to_i
      }
      post_params = generate_params(params)

      res = request(:query_credit_card_period_info, post_params)

      JSON.parse(res.body)
    end

    def credit_detail_do_action(merchant_trade_number, trade_number, action, amount)
      params = {
        MerchantTradeNo: merchant_trade_number,
        TradeNo: trade_number,
        Action: action,
        TotalAmount: amount
      }

      post_params = generate_params(params)

      res = request(:credit_detail_do_action, post_params)

      parse_request_body_to_hash(res)
    end

    private

    def request(type, params = {})
      case type
      when :query_trade_info
        api_url = QUERY_TRADE_INFO_API_ENDPOINTS[@options[:mode]]
      when :query_cc_trade_info
        api_url = QUERY_CC_TRADE_INFO_API_ENDPOINTS[@options[:mode]]
      when :query_credit_card_period_info
        api_url = QUERY_CREDIT_CARD_PERIOD_INFO_API_ENDPOINTS[@options[:mode]]
      when :credit_detail_do_action
        api_url = CREDIT_DETAIL_DO_ACTION_API_ENDPOINTS[@options[:mode]]
        return OpenStruct.new(body: '') unless api_url
      end

      Net::HTTP.post_form URI(api_url), params
    end
  end
end
