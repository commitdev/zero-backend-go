module <% .Files.Repository %>

go 1.14

require (
	github.com/aws/aws-sdk-go v1.37.6
	github.com/jinzhu/gorm v1.9.16
	github.com/joho/godotenv v1.3.0
<%- if eq (index .Params `billingEnabled`) "yes" %>
	github.com/stripe/stripe-go/v72 v72.43.0
<%- end %>
)
