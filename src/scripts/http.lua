local script_name = "http"

local requests = {}
local http_types = { "GET", "PUT", "POST", "DELETE" }

local function newHttp(parent, options)
  local id = parent.___.util.generate_uuid()
  local instance = {
    id = id,
    parent = parent,
    options = options,
    ___ = (function(p)
      while p.parent do p = p.parent end
      return p
    end)(parent)
  }

  -- Headers
  if not options.headers then options.headers = {} end
  if type(options.headers) ~= "table" then
    error("headers must be a table")
  end
  instance.headers = options.headers

  local function write_file(self, filepath, data)
    local dir, file = self.___.fd:dir_file(filepath, true)
    if dir and file then
      return self.___.fd:write_file(filepath, data, true)
    else
      return nil, "Invalid file path."
    end
  end

  local function done(self, response)
    local ob_id = response.id
    local ob = requests[ob_id]

    if self.options.saveTo and not response.error then
      local result = { write_file(self, self.options.saveTo, response.data) }
    end

    local cb = self.options.cb

    cb(response)
    deleteAllNamedEventHandlers(ob_id)
    requests[ob_id] = nil
    ob = nil
    instance = nil
  end

  -- Events to listen for
  local events = {}
  local lc = table.index_of(http_types, options.method) and
    string.lower(options.method) or
    "custom"
  local uc = string.title(instance.___.string:capitalize(lc))

  for _, event in ipairs({"Done", "Error"}) do
    local event_mod = string.format("sys%sHttp%s", uc, event)
    table.insert(events, { event, event_mod })
  end

  local function only_indexed(t)
    local tmp = {}
    for i = 1, #t do
      tmp[i] = t[i]
    end
    return tmp
  end

  for _, event in ipairs(events) do
    local event_type, event_name = unpack(event)
    registerNamedEventHandler(
      instance.id,
      event_name,
      event_name,
      function(e, ...)
        local response = {
          event = e,
          id = instance.id,
          parent = instance,
        }
        local result
        arg = only_indexed(arg)
        if rex.match(e, "sys(?:\\w+)HttpError$") then
          result = instance.___.table:allocate({ "error", "url", "server" }, arg)
        elseif rex.match(e, "sys(?:\\w+)HttpDone$") then
          result = instance.___.table:allocate({ "url", "data", "server" }, arg)
        else
          error("Unknown event: " .. e)
        end

        response = table.union(response, result)

        done(instance, response)
      end
    )
  end

  instance.method_lc = lc
  instance.method_uc = uc
  instance.custom = options.method == "CUSTOM"

  local func_name = string.format("%sHTTP", lc)
  local func = _G[func_name]

  assert(func, "HTTP method " .. func_name .. " not found")
  assert(type(func) == "function", "HTTP method " .. func_name .. " is not a function")

  local ok, err, result = pcall(
    instance.custom and
      function() return func(options.method, options.url, options.headers) end or
      function() return func(options.url, options.headers) end
  )

  if not ok then
    error("Error calling HTTP method " .. tostring(instance.custom) .. " " .. tostring(func) .. ": " .. tostring(err))
  end

  setmetatable(instance, { __index = instance })

  return instance
end

---@diagnostic disable-next-line: undefined-global
local mod = mod or {}
function mod.new(parent)
  local instance = {
    parent = parent,
    type = "http",
    ___ = (function(p)
      while p.parent do p = p.parent end
      return p
    end)(parent)
  }

  local function validate_options(self, options)
    self.___.valid:type(options, "table", 1, false)
    self.___.valid:not_empty(options, 1, false)
    self.___.valid:type(options.method, "string", 2, false)

    -- We must have a URL
    self.___.valid:regex(options.url, self.___.regex.http_url, "url", 1, false)
  end

  --- Downloads a file from the given URL and saves it to the specified path.
  --- You may certainly also use the `get` or `request` methods to download a
  --- file, however, this is a bit more convenient as it does some checking
  --- for you.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:download({
  ---   url = "http://example.com/file.txt",
  ---   saveTo = "path/to/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:download(options, cb)
    options.method = options.method or "GET"
    self.___.valid:type(options.saveTo, "string", 1, false)
    return instance:request(options, cb)
  end

  --- Makes a GET request to the given URL.
  ---
  --- The options table may consist of the following keys:
  ---
  --- - `url` (`string`) - The URL to request.
  --- - `headers` (`table`) - The headers to send with the request.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:get({
  ---   url = "http://example.com/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:get(options, cb)
    options.method = "GET"
    return self:request(options, cb)
  end

  --- Makes a POST request to the given URL.
  ---
  --- The options table may consist of the following keys:
  ---
  --- - `url` (`string`) - The URL to request.
  --- - `headers` (`table`) - The headers to send with the request.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:post({
  ---   url = "http://example.com/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:post(options, cb)
    options.method = "POST"
    return self:request(options, cb)
  end

  --- Makes a PUT request to the given URL.
  ---
  --- The options table may consist of the following keys:
  ---
  --- - `url` (`string`) - The URL to request.
  --- - `headers` (`table`) - The headers to send with the request.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:put({
  ---   url = "http://example.com/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:put(options, cb)
    options.method = "PUT"
    return self:request(options, cb)
  end

  --- Makes a DELETE request to the given URL.
  ---
  --- The options table may consist of the following keys:
  ---
  --- - `url` (`string`) - The URL to request.
  --- - `headers` (`table`) - The headers to send with the request.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:delete({
  ---   url = "http://example.com/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:delete(options, cb)
    options.method = "DELETE"
    return self:request(options, cb)
  end

  --- Makes a request to the given URL. Use this option for any HTTP method
  --- that is not: `GET`, `POST`, `PUT`, or `DELETE`.
  ---
  --- The options table may consist of the following keys:
  ---
  --- - `url` (`string`) - The URL to request.
  --- - `method` (`string`) - The HTTP method to use.
  --- - `headers` (`table`) - The headers to send with the request.
  ---
  --- @param options table - The options for the request.
  --- @param cb function - The callback function.
  --- @return table - The HTTP request object.
  --- @example
  --- ```lua
  --- http:request({
  ---   url = "http://example.com/file.txt"
  --- }, function(response) end)
  --- ```
  function instance:request(options, cb)
    validate_options(self, options)

    -- upper case the method
    options.method = string.upper(options.method)

    -- We must have a callback
    self.___.valid:type(cb, "function", 2, false)
    options.cb = cb

    -- Get a new http object
    local request = newHttp(self, options)
    requests[request.id] = request
    return request
  end

  instance.___.valid = instance.___.valid or setmetatable({}, {
    __index = function(_, k) return function(...) end end
  })

  return instance
end

-- Let Glu know we're here
raiseEvent("glu_module_loaded", script_name, mod)

return mod
