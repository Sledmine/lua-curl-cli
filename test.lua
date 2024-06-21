require "luna"
local curl = require "curl-cli"
local inspect = require "inspect"

curl.debug = true

-- Test GET request
local request = curl.get("https://jsonplaceholder.typicode.com/todos/1")
assert(request.statusCode == 200)
assert(request.error == nil)
assert(request.ok)
assert(request.headers["content-type"] == "application/json; charset=utf-8")
assert(request.text:match("userId"))
assert(request.json(), "json() method failed")
assert(request.json().userId == 1)

request = curl.get {
    url = "https://jsonplaceholder.typicode.com/comments",
    params = {postId = 2},
    headers = {["Accept"] = "application/json", ["User-Agent"] = "curl"}
}
assert(request.statusCode == 200)
assert(request.json()[1].postId == 2)

-- Test POST request
request = curl.post("https://jsonplaceholder.typicode.com/posts", {
    params = {title = "foo", body = "bar", userId = 1}
})
assert(request.statusCode == 201)

request = curl.post {
    url = "https://jsonplaceholder.typicode.com/posts",
    params = {foo = "bar", whitespace = " "},
    headers = {["Content-Type"] = "application/json"},
    data = {title = "foo", body = "bar", userId = 1}
}
assert(request.statusCode == 201)

-- Test PUT request
request = curl.put("https://jsonplaceholder.typicode.com/posts/1", {
    data = {id = 1, title = "foo", body = "bar", userId = 1}
})
assert(request.statusCode == 200)

request = curl.put {
    url = "https://jsonplaceholder.typicode.com/posts/1",
    data = {id = 1, title = "foo", body = "bar", userId = 1}
}
assert(request.statusCode == 200)

-- Test DELETE request
request = curl.delete("https://jsonplaceholder.typicode.com/posts/1")
assert(request.statusCode == 200)

request = curl.delete {
    url = "https://jsonplaceholder.typicode.com/posts/1"
}

-- Test PATCH request
request = curl.patch("https://jsonplaceholder.typicode.com/posts/1", {
    data = {title = "foo"}
})
assert(request.statusCode == 200)

request = curl.patch {
    url = "https://jsonplaceholder.typicode.com/posts/1",
    data = {title = "foo"}
}
assert(request.statusCode == 200)

-- Test 404 error
request = curl.get("https://jsonplaceholder.typicode.com/this-does-not-exist")
assert(request.statusCode == 404)

-- Test unexpected curl error
request = curl.get("https://127.0.0.9")
assert(request.error)

print("All tests passed!")