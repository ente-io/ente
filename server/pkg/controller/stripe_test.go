package controller

import (
	"testing"

	"github.com/stripe/stripe-go/v72"
)

func TestIsPaidStripeInvoice(t *testing.T) {
	tests := []struct {
		name    string
		invoice *stripe.Invoice
		want    bool
	}{
		{
			name:    "paid boolean",
			invoice: &stripe.Invoice{Paid: true, Status: stripe.InvoiceStatusOpen},
			want:    true,
		},
		{
			name:    "paid status",
			invoice: &stripe.Invoice{Status: stripe.InvoiceStatusPaid},
			want:    true,
		},
		{
			name:    "open unpaid invoice",
			invoice: &stripe.Invoice{Status: stripe.InvoiceStatusOpen},
			want:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isPaidStripeInvoice(tt.invoice); got != tt.want {
				t.Fatalf("isPaidStripeInvoice() = %v, want %v", got, tt.want)
			}
		})
	}
}
