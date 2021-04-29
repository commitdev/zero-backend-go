package billing

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	Stripe "github.com/stripe/stripe-go/v72"
	"github.com/stripe/stripe-go/v72/client"
<%- if eq (index .Params `userAuth`) "yes" %>
	"<% .Files.Repository %>/internal/auth"
<%- end %>
)

var backendURL = os.Getenv("BACKEND_URL")
var frontendURL = os.Getenv("FRONTEND_URL")

var Handler = getHandler()
var stripe *client.API

// Subscriptions for frontend to display available plans available for checkout
type Subscriptions struct {
	Nickname string `json:"nickname"`
	Interval string `json:"interval"`
	Type     string `json:"type"`
	ID       string `json:"id"`
	Price    string `json:"price"`
}

func getHandler() http.Handler {
	setupStripe()
	mux := http.NewServeMux()
	mux.HandleFunc("/billing/products", getProducts)
	mux.HandleFunc("/billing/checkout", checkout)
	mux.HandleFunc("/billing/success", success)
	mux.HandleFunc("/billing/cancel", cancel)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Not found"))
	})
	return mux
}

func setupStripe() {
	stripe = &client.API{}
	apiKey := os.Getenv("STRIPE_API_SECRET_KEY")
	stripe.Init(apiKey, nil)
}

func getProducts(w http.ResponseWriter, r *http.Request) {
	active := true
	listParams := &Stripe.PriceListParams{Active: &active}
	stripePriceIterator := stripe.Prices.List(listParams).Iter

	subs := []Subscriptions{}
	// Data to display subscriptions for the frontend example
	for stripePriceIterator.Next() {
		stripePrice := stripePriceIterator.Current().(*Stripe.Price)
		amount := float64(stripePrice.UnitAmount) / 100
		displayPrice := fmt.Sprintf("%s $%.2f/%s", strings.ToUpper(string(stripePrice.Currency)), amount, string(stripePrice.Recurring.Interval))
		sub := Subscriptions{
			Nickname: stripePrice.Nickname,
			Interval: string(stripePrice.Recurring.Interval),
			Type:     string(stripePrice.Type),
			ID:       stripePrice.ID,
			Price:    displayPrice,
		}
		subs = append(subs, sub)
	}
	output, err := json.Marshal(&subs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	w.Write(output)
}

func checkout(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "Incorrect method", http.StatusBadRequest)
		return
	}

	price := struct {
		ID string `json:"price_id"`
	}{}
	err := json.NewDecoder(r.Body).Decode(&price)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	paymentMethod := "card"
	paymentMode := "subscription"
	checkoutQuantity := int64(1)
	lineItem := &Stripe.CheckoutSessionLineItemParams{
		Price:    &price.ID,
		Quantity: &checkoutQuantity,
	}
	successURL := backendURL + "/billing/success?session_id={CHECKOUT_SESSION_ID}"
	cancelURL := backendURL + "/billing/cancel?session_id={CHECKOUT_SESSION_ID}"
<% if eq (index .Params `userAuth`) "yes" %>
	authErr, userInfo := auth.GetUserInfoFromHeaders(r)
	clientReferenceID := userInfo.ID
	if authErr != nil {
		http.Error(w, authErr.Error(), http.StatusUnauthorized)
		return
	}
	<%- else %>
	clientReferenceID := "internal-app-reference-id"
	<%- end %>

	checkoutParams := &Stripe.CheckoutSessionParams{
		Mode:               &paymentMode,
		PaymentMethodTypes: []*string{&paymentMethod},
		ClientReferenceID:  &clientReferenceID,
		LineItems:          []*Stripe.CheckoutSessionLineItemParams{lineItem},
		SuccessURL:         &successURL,
		CancelURL:          &cancelURL,
	}
	session, err := stripe.CheckoutSessions.New(checkoutParams)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, `{"sessionId": "%s"}`, session.ID)
}

func success(w http.ResponseWriter, r *http.Request) {
	sessionId := string(r.URL.Query().Get("session_id"))

	session, err := stripe.CheckoutSessions.Get(sessionId, &Stripe.CheckoutSessionParams{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	data := map[string]string{
		"payment_status": string(session.PaymentStatus),
		"amount":         fmt.Sprintf("%d", session.AmountSubtotal),
		"currency":       string(session.Currency),
		"customer":       string(session.CustomerDetails.Email),
		"reference":      string(session.ClientReferenceID),
	}

	redirectURL := fmt.Sprintf("%s%s?%s", frontendURL, "/billing/confirmation", mapToQueryString(data))
	http.Redirect(w, r, redirectURL, 302)
}

func cancel(w http.ResponseWriter, r *http.Request) {
	sessionId := string(r.URL.Query().Get("session_id"))

	session, err := stripe.CheckoutSessions.Get(sessionId, &Stripe.CheckoutSessionParams{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	data := map[string]string{
		"payment_status": string(session.PaymentStatus),
		"amount":         fmt.Sprintf("%d", session.AmountSubtotal),
		"currency":       string(session.Currency),
		"reference":      string(session.ClientReferenceID),
	}
	redirectURL := fmt.Sprintf("%s%s?%s", frontendURL, "/billing/confirmation", mapToQueryString(data))
	http.Redirect(w, r, redirectURL, 302)
}

func mapToQueryString(data map[string]string) string {
	i := 0
	params := make([]string, len(data))
	for k, v := range data {
		params[i] = fmt.Sprintf("%s=%s", k, v)
		i++
	}
	return strings.Join(params, "&")
}
