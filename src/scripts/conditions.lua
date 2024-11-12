local ConditionsClass = Glu.glass.register({
  class_name = "ConditionsClass",
  name = "conditions",
  dependencies = {},
  setup = function(___, self)
    --- Checks if a condition is true or false.
    --- @param condition boolean - The condition to check
    --- @param message string|nil - The message to return if the condition is false
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is(condition, message)
      assert(type(condition) == "boolean", "Expected a boolean as the first argument")
      assert(type(message) == "string" or message == nil, "Expected a string or nil as the second argument")

      raiseEvent("condition_is", condition)
      return condition, condition and nil or message
    end

    --- Checks if a condition is true.
    --- @param condition boolean - The condition to check
    --- @param message string|nil - The message to return if the condition is false
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_true(condition, message)
      return self.is(condition, message or "Expected condition to be true")
    end

    --- Checks if a condition is false.
    --- @param condition boolean - The condition to check
    --- @param message string|nil - The message to return if the condition is true
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_false(condition, message)
      return self.is(not condition, message or "Expected condition to be false")
    end

    --- Checks if a value is nil.
    --- @param value any - The value to check
    --- @param message string|nil - The message to return if the value is not nil
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_nil(value, message)
      return self.is(value == nil, message or "Expected `{value}` to be nil")
    end

    --- Checks if a value is not nil.
    --- @param value any - The value to check
    --- @param message string|nil - The message to return if the value is nil
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_not_nil(value, message)
      return self.is(value ~= nil, message or "Expected `{value}` to not be nil")
    end

    --- Checks if a function throws an error.
    --- @param func function - The function to check
    --- @param message string|nil - The message to return if the function does not throw an error
    --- @param check function|nil - The function to check the error message against
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_error(func, message, check)
      assert(type(func) == "function", "Expected a function as the first argument")
      assert(type(message) == "string" or message == nil, "Expected a string or nil as the second argument")
      assert(type(check) == "function" or check == nil, "Expected a function or nil as the third argument")

      local test_success, test_err = pcall(func)
      local error_success, error_err

      if not test_success then
        if(check) then
          error_success, error_err = pcall(check, test_err, self)
        else
          error_success, error_err = true, nil
        end
      end

      -- If `pcall` fails (returns false), we know the function threw an error
      return self.is(not error_success,
        message or f "Expected function to throw an error but it did not. Error: {error_err}"
      )
    end

    --- Checks if two values are equal.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not equal
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_eq(a, b, message)
      return self.is(a == b,
        message or f "Expected `{a}` to equal `{b}`\n")
    end

    --- Checks if two values are not equal.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are equal
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_ne(a, b, message)
      return self.is(a ~= b,
        message or f "Expected `{a}` to not equal `{b}`\n")
    end

    --- Checks if a value is less than another value.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not less than
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_lt(a, b, message)
      return self.is(a < b,
        message or f "Expected `{a}` to be less than `{b}`\n")
    end

    --- Checks if a value is less than or equal to another value.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not less than or equal to
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_le(a, b, message)
      return self.is(a <= b,
        message or f "Expected `{a}` to be less than or equal to `{b}`\n")
    end

    --- Checks if a value is greater than another value.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not greater than
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_gt(a, b, message)
      return self.is(a > b,
        message or f "Expected `{a}` to be greater than `{b}`\n")
    end

    --- Checks if a value is greater than or equal to another value.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not greater than or equal to
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_ge(a, b, message)
      return self.is(a >= b, message or f "Expected `{a}` to be greater than or equal to `{b}`\n")
    end

    --- Checks if a value is of a specific type.
    --- @param value any - The value to check
    --- @param type string - The type to check against
    --- @param message string|nil - The message to return if the values are not of the specified type
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_type(value, type, message)
      return self.is(type(value) == type, message or f "Expected `{value}` to be of type `{type}`\n")
    end

    --- Checks if two values are deeply equal.
    --- @param a any - The first value to check
    --- @param b any - The second value to check
    --- @param message string|nil - The message to return if the values are not deeply equal
    --- @return boolean - The condition
    --- @return string|nil - The message
    function self.is_deeply(a, b, message)
      local result, mess

      local function deep_compare(first, second, visited)
        visited = visited or {}

        -- If both values are not tables, use is_eq for proper state tracking
        if type(first) ~= "table" or type(second) ~= "table" then
          result, mess = self.is_eq(first, second, message or f "Expected `{first}` to equal `{second}`")

          return result, result and nil or mess
        end

        -- If we've seen this pair of tables before, they're equal
        for v1, v2 in pairs(visited) do
          if v1 == first and v2 == second then
            return true
          end
        end

        -- Mark these tables as being compared
        visited[first] = second

        -- Compare all keys and values
        for k, v in pairs(first) do
          if second[k] == nil then
            return false, f "Key `{k}` missing in second table"
          end

          local equal, err = deep_compare(v, second[k], visited)
          if not equal then
            return false, err
          end
        end

        -- Check for extra keys in second
        for k in pairs(second) do
          if first[k] == nil then
            return false, f "Extra key `{k}` in second table"
          end
        end

        return true
      end

      return deep_compare(a, b, {})
    end
  end
})
