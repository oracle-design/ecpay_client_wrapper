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

test_client.request(
  '/Cashier/QueryTradeInfo',
  MerchantTradeNo: '0457ce27',
  TimeStamp: Time.current.to_i
)


logistic_test_client = Ecpay::LogisticClient.new(mode: :test, logistics_sub_type: :FAMI)

logistic_production_client = Ecpay::LogisticClient.new({
  merchant_id: 'MERCHANT_ID',
  hash_key: 'HASH_KEY',
  hash_iv: 'HASH_IV'
})
```

本文件撰寫時，參考全方位金流介接技術文件 V5.1.22：

詳細 API 參數請參閱綠界金流介接技術文件，注意幾點：

- 使用時不用煩惱 `MerchantID` 與 `CheckMacValue`，正如上述範例一樣。
- `/Cashier/AioCheckOut/V5` 回傳的內容是 HTML，這個請求應該是交給瀏覽器發送的，所以不應該寫出 `client.request '/Cashier/AioCheckOut/V5'` 這樣的程式碼。

## Ecpay::Client

| 實體方法                                                     | 回傳                | 說明                                                                                                               |
| ------------------------------------------------------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `request(path, **params)`                                    | `Net::HTTPResponse` | 發送 API 請求                                                                                                      |
| `make_mac(**params)`                                         | `String`            | 用於產生 `CheckMacValue`，單純做加密，`params` 需要完整包含到 `MerchantID`                                         |
| `verify_mac(**params)`                                       | `Boolean`           | 用於檢查收到的參數，其檢查碼是否正確，這用在綠界的 `ReturnURL` 與 `PeriodReturnURL` 參數上。                       |
| `query_trade_info(merchant_trade_number, platform = nil)`    | `Hash`              | `/Cashier/QueryTradeInfo/V5` 的捷徑方法，將 `TimeStamp` 設定為當前時間                                             |
| `query_credit_card_period_info(merchant_trade_number)`       | `Hash`              | `/Cashier/QueryCreditCardPeriodInfo` 的捷徑方法，將 `TimeStamp` 設定為當前時間                                     |
| `generate_checkout_params`                                   | `Hash`              | 用於產生 `/Cashier/AioCheckOut/V5` 表單需要的參數，`MerchantTradeDate`、`MerchantTradeNo`、`PaymentType`，可省略。 |

## License

MIT
