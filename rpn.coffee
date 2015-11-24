readline = require 'readline'

# ------ readline input handling -----
rl = readline.createInterface(process.stdin, process.stdout)
rl.setPrompt '> '

gracefulExit = ->
    console.log "\nexiting"
    process.exit 0

rl.on 'line', (line) ->
    gracefulExit() if line is "q"
    processLine line
    rl.prompt()

rl.on 'close', gracefulExit

rl.prompt()

# ------ stack processing -----
stack = []

isScalar = (str) ->
    num = parseFloat str
    return !isNaN(num) && isFinite(num)

processLine = (line) ->
    line = line.trim()

    num = parseFloat line
    if isScalar num
        stack.push num
        return console.log num

    validOperations = ['+', '-', '*', '/']
    return console.log "not a valid input" unless line in validOperations

    return console.log 'binary math operations require 2 numeric operands on the stack' unless stack.length >= 2

    # If we got here, it is a valid binary math operation.
    [n1, n2] = stack.splice(stack.length - 2)

    switch line
        when '+'
            result = n1 + n2
        when '-'
            result = n1 - n2
        when '*'
            result = n1 * n2
        when '/'
            result = n1 / n2
    stack.push result
    console.log result
