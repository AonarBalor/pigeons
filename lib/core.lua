local core = {}

-- ok, I added env and it looks kinda silly now. oh well.
core.print_message = function (_, env)
    print(math.floor(env.now * 1000)..' - message of type '
        ..env.message_type..':')
    for k, v in pairs(env.message) do
        print(k .. ' = ' .. v)
    end
end

core.print_expr = function (args, env)
    local printable = args[1]
    -- assume we only care about first arg of expression
    local result = lisp.exec(printable, env)
    print(utils.table_to_string(result))
end

core.print_table = function (args, env)
    print(utils.table_to_string(args[1]))
end

core.eq = function (args, env)
    return lisp.exec(args[1], env) == lisp.exec(args[2], env)
end

core['not'] = function (args, env)
    return not lisp.exec(args[1], env)
end

core['and'] = function (args, env)
    local result = true
    for i=1,#args do
        if not lisp.exec(args[i], env) then
            return false
        end
    end
    return result
end

core['or'] = function (args, env)
    local result = false
    for i=1,#args do
        if lisp.exec(args[i], env) then
            return true
        end
    end
    return result
end

core.cond = function (args, env)
    local result = lisp.exec(args[1], env)
    if result then
        return lisp.exec(args[2], env)
    else
        return lisp.exec(args[3], env)
    end
end

core.smush = function (args, env)
    local str = ""
    for i=1,#args do
        local val = lisp.exec(args[i], env)
        if type(val) == 'boolean' then
            val = val and '(true)' or '(false)'
        end
        str = str..(val or "(nil)")
    end
    return str
end

core.message_prop = function (args, env)
    local prop = args[1]
    -- TODO: validate / handle errors
    return env[prop]
end

-- I got a feeling this one's gonna be short-lived
core.warn_bogus = function (_, env)
    utils.warn(math.floor(env.now * 1000)..' - message of type '
        ..env.message_type..' has some bogus stuff!')
end

-- gonna want defn too, eventually
-- that sounds like a pain
core.def = function(args, env)
    if type(args[1]) ~= 'string' then
        error("def name is not a string, what the heck dude?")
        return nil
    elseif args[2] ~= nil then
        utils.warn("what's the point of defining "..args[1].." as (nil)?")
    end

    return env[args[1]] == args[2]
    -- do we care if we're re-defining an existing name?
    -- nah, not yet. REASONS TO CARE NEEDED
end

-- mayyyybe a bad idea
core.defglobal = function(args, env)
    if type(args[1]) ~= 'string' then
        error("non-string key to defglobal")
    elseif type(args[2]) == nil then
        error("nil value to defglobal")
    else
        -- totally fine to eval here
        lisp.defglobal(args[1], lisp.exec(args[2], env))
    end
end

core['do'] = function(args, env)
    local result
    for i=1,#args do
        result = lisp.exec(args[i], env)
    end
    return result
end

core['pairs-to-table'] = function (args, env)
    local t = {}
    local count = #args
    for i=1, #args, 2  do
        if i+1 <= #args then
            local k = lisp.exec(args[i], env)
            local v = lisp.exec(args[i + 1], env)
            if type(k) == 'string' and v ~= nil then
                t[k] = t[v]
            end
        end 
    end
end

core['tx'] = function(args, env)
    local message_type = lisp.exec(args[1], env)
    local msg = lisp.exec(args[2], env)
    message.transmit(message_type, msg)
end


-- stinky
-- could probably just iterate over all these keys
lisp.defglobal('print-message', core.print_message)
lisp.defglobal('print-expr', core.print_expr)
lisp.defglobal('print-table', core.print_table)
lisp.defglobal('smush', core.smush)
lisp.defglobal('if', core.cond)
lisp.defglobal('=', core.eq)
lisp.defglobal('and', core['and'])
lisp.defglobal('not', core['not'])
lisp.defglobal('message-prop', core.message_prop)
lisp.defglobal('def', core.def)
lisp.defglobal('defglobal', core.defglobal)
lisp.defglobal('do', core['do'])

return core
