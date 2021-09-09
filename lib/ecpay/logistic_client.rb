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

    C2C_UNIMART_ORDER_INFO_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/PrintUniMartC2COrderInfo',
      production: 'https://logistics.ecpay.com.tw/Express/PrintUniMartC2COrderInfo'
    }.freeze

    C2C_FAMI_ORDER_INFO_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/PrintFAMIC2COrderInfo',
      production: 'https://logistics.ecpay.com.tw/Express/PrintFAMIC2COrderInfo'
    }.freeze

    C2C_HILIFE_ORDER_INFO_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/PrintHILIFEC2COrderInfo',
      production: 'https://logistics.ecpay.com.tw/Express/PrintHILIFEC2COrderInfo'
    }.freeze

    C2C_OKMART_ORDER_INFO_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/Express/PrintOKMARTC2COrderInfo',
      production: 'https://logistics.ecpay.com.tw/Express/PrintOKMARTC2COrderInfo'
    }.freeze

    B2C_CVS_AND_HOME_TRADE_DOC_END_POINTS = {
      test: 'https://logistics-stage.ecpay.com.tw/helper/printTradeDocument',
      production: 'https://logistics.ecpay.com.tw/helper/printTradeDocument'
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
        when :FAMIC2C, :UNIMARTC2C, :HILIFEC2C, :OKMARTC2C
          @options.merge!(C2C_TEST_OPTIONS)
        else
          raise InvalidLogisticSubType, %(option :logistics_sub_type is not in option list please check document https://www.ecpay.com.tw/Content/files/ecpay_030.pdf)
        end
      else
        raise InvalidMode, %(option :mode is either :test or :production)
      end

      @options.freeze
    end

    def generate_label_form_data_for_unimart_c2c(params)
      param_required! params, %i[
        AllPayLogisticsID
        CVSPaymentNo
        CVSValidationNo
      ]

      # Optional params:
      # PlatformID

      generate_form_data(:generate_label_form_data_for_unimart_c2c, params)
    end

    def generate_label_form_data_for_fami_c2c(params)
      param_required! params, %i[
        AllPayLogisticsID
        CVSPaymentNo
      ]

      # Optional params:
      # PlatformID

      generate_form_data(:generate_label_form_data_for_fami_c2c, params)
    end

    def generate_label_form_data_for_hilife_c2c(params)
      param_required! params, %i[
        AllPayLogisticsID
        CVSPaymentNo
      ]

      # Optional params:
      # PlatformID

      generate_form_data(:generate_label_form_data_for_hilife_c2c, params)
    end

    def generate_label_form_data_for_okmart_c2c(params)
      param_required! params, %i[
        AllPayLogisticsID
        CVSPaymentNo
      ]

      # Optional params:
      # PlatformID

      generate_form_data(:generate_label_form_data_for_okmart_c2c, params)
    end

    def generate_label_form_data_for_b2c_and_home(params)
      param_required! params, %i[
        AllPayLogisticsID
      ]

      # Optional params:
      # PlatformID

      generate_form_data(:generate_label_form_data_for_b2c_and_home, params)
    end

    private

    def generate_form_data(type, params)
      case type
      when :generate_label_form_data_for_unimart_c2c
        api_base = C2C_UNIMART_ORDER_INFO_END_POINTS[@options[:mode]]
      when :generate_label_form_data_for_fami_c2c
        api_base = C2C_FAMI_ORDER_INFO_END_POINTS[@options[:mode]]
      when :generate_label_form_data_for_hilife_c2c
        api_base = C2C_HILIFE_ORDER_INFO_END_POINTS[@options[:mode]]
      when :generate_label_form_data_for_okmart_c2c
        api_base = C2C_OKMART_ORDER_INFO_END_POINTS[@options[:mode]]
      when :generate_label_form_data_for_b2c_and_home
        api_base = B2C_CVS_AND_HOME_TRADE_DOC_END_POINTS[@options[:mode]]
      end

      post_params = generate_params(params.compact)

      OpenStruct.new(api_base: api_base, post_params: post_params)
    end
  end
end
