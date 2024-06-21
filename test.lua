local curl = require "curl-cli"
local inspect = require "inspect"

curl.debug = true

local request = curl.get("https://jsonplaceholder.typicode.com/todos/1")
assert(request.code == 200)
assert(request.headers["content-type"] == "application/json; charset=utf-8")
assert(request.text:match("userId"))
assert(request.json(), "json() method failed")
assert(request.json().userId == 1)
assert(request.error == nil)

local request = curl.get {
    url = "https://jsonplaceholder.typicode.com/todos/1",
    headers = {["Accept"] = "application/json", ["User-Agent"] = "curl"}
}
assert(request.code == 200)

local request = curl.post("https://jsonplaceholder.typicode.com/posts", {title = "foo", body = "bar", userId = 1})
assert(request.code == 201)

local request = curl.post {
    url = "https://jsonplaceholder.typicode.com/posts",
    params = {foo = "bar"},
    headers = {["Content-Type"] = "application/json"},
    data = {title = "foo", body = "bar", userId = 1}
}
assert(request.code == 201)