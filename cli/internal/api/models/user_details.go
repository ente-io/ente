package models

type UserDetails struct {
	User  User   `json:"user"`
	Usage int64  `json:"usage"`
	Email string `json:"email"`

	Subscription struct {
		ExpiryTime      int64  `json:"expiryTime"`
		Storage         int64  `json:"storage"`
		ProductID       string `json:"productID"`
		PaymentProvider string `json:"paymentProvider"`
	} `json:"subscription"`
}

type User struct {
	ID           int64
	Email        string `json:"email"`
	Hash         string `json:"hash"`
	CreationTime int64  `json:"creationTime"`
}
