package models

type UserDetails struct {
	User struct {
		ID int64 `json:"id"`
	} `json:"user"`
	Usage int64  `json:"usage"`
	Email string `json:"email"`

	Subscription struct {
		ExpiryTime      int64  `json:"expiryTime"`
		Storage         int64  `json:"storage"`
		ProductID       string `json:"productID"`
		PaymentProvider string `json:"paymentProvider"`
	} `json:"subscription"`
}
