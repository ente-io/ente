package ente

// BlackFridayOffer represents the latest Black Friday Offer
type BlackFridayOffer struct {
	ID            string `json:"id"`
	Storage       int64  `json:"storage"`
	Price         string `json:"price"`
	OldPrice      string `json:"oldPrice"`
	PeriodInYears string `json:"periodInYears"`
	PaymentLink   string `json:"paymentLink"`
}

type BlackFridayOfferPerCountry map[string][]BlackFridayOffer
