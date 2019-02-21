# Ecpay 綠界 API Wrapper

Fork from https://github.com/CalvertYang/ecpay

這是綠界 API 的 Ruby 包裝，更多資訊參考他們的[官方文件](https://www.ecpay.com.tw/Content/files/ecpay_011.pdf)。

API 相關文件可參考 [ezPay 串接規格下載](https://www.ecpay.com.tw/Service/API_Dwnld)。

## 安裝

```rb
# in gemfile
gem 'ecpay_client_wrapper', github: 'oracle-design/ecpay_client_wrapper', branch: 'master'
```

## 使用

```ruby
test_client = Ecpay::Client.new(mode: :test)
production_client = Ecpay::Client.new({
  merchant_id: 'MERCHANT_ID',
  hash_key: 'HASH_KEY',
  hash_iv: 'HASH_IV'
})

test_client.generate_checkout_params({
  MerchantTradeNo: 'ab1234567',
  TotalAmount: 1000,
  TradeDesc: 'Odd VIP遊戲室使用卷x10'
})


logistic_test_client = Ecpay::LogisticClient.new(mode: :test, logistics_sub_type: :FAMI)

logistic_production_client = Ecpay::LogisticClient.new({
  merchant_id: 'MERCHANT_ID',
  hash_key: 'HASH_KEY',
  hash_iv: 'HASH_IV'
})
```

本文件撰寫時，參考:

- [綠界科技全方位金流介接技術文件](https://www.ecpay.com.tw/Content/files/ecpay_011.pdf)
  - V 5.1.22
  - 文件編號 gw_p100
  - 2018-11-05
- [綠界科技物流整合 API 介接技術文件](https://www.ecpay.com.tw/Content/files/ecpay_030.pdf)
  - V 2.3.1
  - 文件編號:gw_l100
  - 2019-01-02

詳細 API 參數請參閱綠界金流介接技術文件，注意幾點：

- 使用時不用煩惱 `MerchantID` 與 `CheckMacValue`，正如上述範例一樣。
- 物流（`Ecpay::LogisticClient`）與金流（`Ecpay::Client`）分別使用 `MD5` 與 `SHA256` 來作加密，使用時不需擔心加密規則。
- 物流 `Ecpay::LogisticClient` 因測試環境依據不同的物流子類別，綠界要求使用不同的商店，所以在此必須把`logistics_sub_type`參數帶入，程式將會自動帶入不同的測試商店參數 ex: `Ecpay::LogisticClient.new(mode: :test, logistics_sub_type: :FAMI)`。 可使用的參數為:
  - :FAMI
  - :UNIMART
  - :HILIFE
  - :TCAT
  - :ECAN
  - :FAMIC2C
  - :UNIMARTC2C
  - :HILIFEC2C

## Ecpay::Client

| 實體方法                                                  | 回傳   | 說明                                                                                                               |
| --------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------ |
| `query_trade_info(merchant_trade_number, platform = nil)` | `Hash` | `/Cashier/QueryTradeInfo/V5` 的捷徑方法，將 `TimeStamp` 設定為當前時間                                             |
| `query_credit_card_period_info(merchant_trade_number)`    | `Hash` | `/Cashier/QueryCreditCardPeriodInfo` 的捷徑方法，將 `TimeStamp` 設定為當前時間                                     |
| `generate_checkout_params(**params)`                      | `Hash` | 用於產生 `/Cashier/AioCheckOut/V5` 表單需要的參數，`MerchantTradeDate`、`MerchantTradeNo`、`PaymentType`，可省略。 |

## Ecpay::LogisticClient

| 實體方法                             | 回傳   | 說明                                                                                                   |
| ------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------ |
| `generate_checkout_params(**params)` | `Hash` | 用於產生 `/Express/Create` 表單需要的參數，`MerchantTradeDate`、`PaymentType`、`EncryptType`，可省略。 |

- 選取超商資訊時可使用 `generate_params(**params)`，來產生需要的參數，再對 `/Express/map` 送出 post 表單

## Ecpay::Helpers 可於上述兩個 Client 中呼叫

| 實體方法                                                     | 回傳                | 說明                                                                                         |
| ------------------------------------------------------------ | ------------------- | -------------------------------------------------------------------------------------------- |
| `make_mac(**params)`                                         | `String`            | 用於產生 `CheckMacValue`，單純做加密，`params` 需要完整包含到 `MerchantID`                   |
| `verify_mac(**params)`                                       | `Boolean`           | 用於檢查收到的參數，其檢查碼是否正確，這用在綠界的 `ReturnURL` 與 `PeriodReturnURL` 參數上。 |
| `generate_params(**params)`                                  | `Hash`              | 自動帶入 `MerchantID` 並與其他參數合併之後產生 `CheckMacValue`                               |

## License

MIT
