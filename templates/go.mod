module <% .Files.Repository %>

go 1.14

require (
	github.com/aws/aws-sdk-go v1.37.6
	github.com/jinzhu/gorm v1.9.16
	github.com/joho/godotenv v1.3.0
<%- if eq (index .Params `billingEnabled`) "yes" %>
	github.com/stripe/stripe-go/v72 v72.43.0
<%- end %>
<%- if eq (index .Params `cacheStore`) "redis" %>
	github.com/go-redis/redis/v8 v8.11.4
<%- end %>
<%- if eq (index .Params `cacheStore`) "memcached" %>
	github.com/bradfitz/gomemcache/memcache v0.0.0-20190913173617-a41fca850d0b
<%- end %>
)
