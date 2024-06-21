require "luna"
local _, json = pcall(require, "json")

local curl = {}

-- JSON backend module, you can replace it with any other JSON module
curl.json = json

local HTTP_PROTOCOL_VERSION_PATTERN = "^HTTP/[1-9]* (%d+)"
local HEADER_PATTERN = "^([%w-]+):%s*(.+)"
local CURL_ERROR_PATTERN = "^curl: "

-- @class httpResponse<T> : { url: string, code: number, text: string, headers: table<string, string>, json : fun(): T }

---@class httpResponse
---@field url string
---@field code number
---@field text string
---@field headers table<string, string>
---@field json fun(): table
---@field error string?

curl.debug = false

-- Probably an alternative due to performance
-- https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local function urlencode(str)
    -- str = string.gsub(str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
    str = string.gsub(str, "([ '])", -- locale independent
    function(c) return string.format("%%%02X", string.byte(c)) end)
    str = string.gsub(str, " ", "+")
    return str
end

--- Get a URL using curl
---@overload fun(url: string): httpResponse
---@param args { url: string, headers: table<string, string> }
---@return httpResponse
function curl.get(args)
    local url
    local requestHeaders = {}
    if type(args) == "string" then
        url = args
    else
        url = args.url
        for key, value in pairs(args.headers) do
            table.insert(requestHeaders,
                         string.format("-H '%s: %s'", key, value))
        end
    end
    local cmd = string.format("curl -i -sS '%s' " ..
                                  table.concat(requestHeaders, " ") .. " 2>&1",
                              url)
    if curl.debug then print("curl command: " .. cmd) end
    local result = assert(io.popen(cmd, "r"))
    local code = 0
    local text = ""
    local responseHeaders = {}
    local error

    local line = result:read("l")
    if not line then error("curl failed to execute") end

    if line:match(CURL_ERROR_PATTERN) then error = line end

    -- Get body
    while line do
        -- Get http status code, ignore HTTP version
        if line:match(HTTP_PROTOCOL_VERSION_PATTERN) then
            code = tonumber(line:match(HTTP_PROTOCOL_VERSION_PATTERN)) or code
        elseif line:match(HEADER_PATTERN) then
            local key, value = line:match(HEADER_PATTERN)
            responseHeaders[key:lower()] = value
        else
            text = text .. line
        end

        line = result:read("l")
        if line then line = line:trim() end
    end

    result:close()
    return {
        text = text,
        headers = responseHeaders,
        code = code,
        error = error,
        url = url,
        json = function()
            local _, json = pcall(json.decode, text)
            return json
        end
    }
end

--- Post a URL using curl
---@overload fun(url: string, data: string | table): httpResponse
---@param args { url: string, headers: table<string, string>, data: string | table, params: table<string, string>, form: boolean }
---@return httpResponse
function curl.post(args, ...)
    local url
    if type(args) == "string" then
        url = args
        local varargs = {...}
        args = {url = url, data = varargs[1]}
    else
        url = args.url
    end
    local requestHeaders = {}
    if args.headers then
        for key, value in pairs(args.headers) do
            table.insert(requestHeaders,
                         string.format("-H '%s: %s'", key, value))
        end
    end
    local data
    if type(args.data) == "table" then
        data = json.encode(args.data)
    else
        data = args.data
    end
    local params
    if args.params then
        params = {}
        for key, value in pairs(args.params) do
            table.insert(params, string.format("%s=%s", urlencode(key),
                                               urlencode(value)))
        end
        url = url .. "?" .. table.concat(params, "&")
    end
    local cmd = string.format("curl -i -sS -X POST '%s' " ..
                                  table.concat(requestHeaders, " "), url)
    if data then
        if not args.form then
            cmd = cmd .. string.format(" -d '%s'", data)
        else
            cmd = cmd .. string.format(" --form '%s'", data)
        end
    end
    if curl.debug then print("curl command: " .. cmd) end
    local result = assert(io.popen(cmd, "r"))
    local code = 0
    local text = ""
    local responseHeaders = {}
    local error

    local line = result:read("l")
    if not line then error("curl failed to execute") end

    if line:match(CURL_ERROR_PATTERN) then error = line end

    -- Get body
    while line do
        -- Get http status code, ignore HTTP version
        if line:match(HTTP_PROTOCOL_VERSION_PATTERN) then
            code = tonumber(line:match(HTTP_PROTOCOL_VERSION_PATTERN)) or code
        elseif line:match(HEADER_PATTERN) then
            local key, value = line:match(HEADER_PATTERN)
            responseHeaders[key:lower()] = value
        else
            text = text .. line
        end

        line = result:read("l")
        if line then line = line:trim() end
    end

    result:close()
    return {
        text = text,
        headers = responseHeaders,
        code = code,
        error = error,
        url = url,
        json = function()
            local _, json = pcall(json.decode, text)
            return json
        end
    }
end

return curl
