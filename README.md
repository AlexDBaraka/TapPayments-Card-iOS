# Why the need of this fork?

At baraka we allow users to input their debit card infos whenever they want to add a debit card as a deposit method. We already had a UI form where users can input their account holder name, card number, expiry and CVV. We didn't want to use Tap Payments UI form and keep our own. But we want also to use Tap Payments tokenization process. That's why we create this fork.

# Fork changes

In the source repository, when initializing the tap payments card view, it only allows us to inject card number and card expiry. We can't pass card holder name and CVV forcing us to use Tap Payments UI form.
In this fork, you will be able to pass card holder name and CVV directly from your UI.

Code changes:
- Add `cardHolderName` field to hold a reference of card holder name inside `TapCardView`
- Add `cardCVV` field to hold a reference of card cvv inside `TapCardView`
- Add inside `webview` javascript evaluation `cardHolderName` and `cardCVV`
- Add inside `TapCardView` initializer `initTapCardSDK` two new parameters `cardHolderName` and `cardCVV`
- `cardCVV` field is sanitized by using `tap_byRemovingAllCharactersExcept `

# Integration Flow

1. You will have to create a variable of type TapCardView programmatically:
  ```swift
  private let tapCardView = TapCardView()
  ```
2. You need to hide this TapCardView to not appear on screen and add it to your views hierarchy inside a view controller:
  ```swift
  tapCardView.isHidden = true
  view.addSubview(tapCardView)
  ```
3. Get the debit card infos from your UI
  ```swift
  struct CardForm {
    let cardHolderName: String
    let cardNumber: String
    let cardExpiry: String
    let cardCVV: String
  }
  ```
4. Get Tap Payments parameters
   It should be a dictionnary of type `[String: Any]`.
   It should have the mandatory keys `scope`, `operator`, `purpose`, `order`, `customer` and `merchant`.
   Please refer to the source [documentation](https://developers.tap.company/docs/card-sdk-ios#advanced-integration) to see examples.
   
5. Conform to Tap Payments delegate and handle success, error and invalid inputs
 ```swift
  extension ViewController: TapCardViewDelegate {
    func onSuccess(data: String) { ... }
    func onError(data: String) { ... }
    func onInvalidInput(invalid: Bool) {
        guard !invalid else { return }
        
        tapCardView.generateTapToken()
    }
  }
  ```
6. Call `initTapCardSDK` with debit card infos from step 3 and tap payments parameters from step 4
```swift
  let form = debitCardInfos
  let parameters = tapPaymentsParameters

  tapCardView.initTapCardSDK(
    configDict: parameters,
    delegate: host,
    cardNumber: form.number,
    cardExpiry: form.expiryDate,
    cardCVV: form.cvv,
    cardHolderName: form.holder
  )
```

## For more infos please refer to source [documentation](https://developers.tap.company/docs/card-sdk-ios)
