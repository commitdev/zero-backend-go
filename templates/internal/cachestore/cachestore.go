package cachestore

import (
	"os"
	"fmt"
<%if eq (index .Params `cacheStore`) "redis" %>	
	"context"
	"github.com/go-redis/redis/v8"
<% end %>
<%if eq (index .Params `cacheStore`) "memcached" %>	
	"github.com/bradfitz/gomemcache/memcache"
<% end %>
)

var cacheEndpoint = os.Getenv("CACHE_ENDPOINT")
var cachePort = os.Getenv("CACHE_PORT")

<%if eq (index .Params `cacheStore`) "redis" %>	
func TestConnection() {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cacheEndpoint, cachePort),
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	err := rdb.Set(ctx, "cache-test", "value", 0).Err()
	if err != nil {
		panic(err)
	}
}
<% end %>

<%if eq (index .Params `cacheStore`) "memcached" %>	
func TestConnection() {
	mc := memcache.New(fmt.Sprintf("%s:%s", cacheEndpoint, cachePort))
	err := mc.Set(&memcache.Item{Key: "cache-test", Value: []byte("value")})
	if err != nil {
		panic(err)
	}
}
<% end %>
