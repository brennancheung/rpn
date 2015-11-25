readline = require 'readline'

class Tokenizer
    @tokenize: (input) ->
        # First pass is simple tokenization.
        # There are only 3 things we need to deal with
        # at this stage: whitespace, tokens, and strings.
        tokens = []
        state = 'whitespace'

        value = ''
        whitespaceChars = [" ", "\r", "\n", "\t"]

        for i in [0..(input.length-1)]
            ch = input[i]
            switch state
                when 'whitespace'
                    continue if ch in whitespaceChars
                    if ch is '"'
                        state = 'string'
                        value = ''
                    else
                        state = 'token'
                        value = ch
                when 'token'
                    if ch in whitespaceChars
                        tokens.push {type: 'token', value: value}
                        value = ''
                        state = 'whitespace'
                    else
                        value = value + ch
                when 'string'
                    if ch is '"'
                        state = 'whitespace'
                        tokens.push {type: 'string', value: value}
                    else
                        value = value + ch

        switch state
            when 'token'
                tokens.push {type: 'token', value: value}

        # The 2nd pass is to cast simple scalar values from tokens.
        # Scalars are: string, null, boolean, and numeric.
        tokens = tokens.map (token) ->
            {type, value} = token
            return token if type is 'string'
            return {type: 'null', value: null} if value is 'null'
            return {type: 'boolean', value: true} if value is 'true'
            return {type: 'boolean', value: false} if value is 'false'
            num = parseFloat value
            return {type: 'numeric', value: num} if !isNaN(num) && isFinite(num)
            # can't determine anything more in this pass
            return token
            
        return tokens

class Parser
    constructor: (tokens) ->
        @tokens = tokens

        @stacks = [[]] # a stack of stacks :)
        # Needed due to the semi-recursive nature of parsing arrays.
        # Basically, when an array is started ('[') a new stack is created.
        # When the array is terminated (']'), the most recent stack gets popped
        # and then pushed as an array element into the last stack.
        # Ex:
        #     If we parse: "1 2 [ 3 [ 4 5 ] 6 ]" it proceeds as follows:
        #     [ [1] ]                      # append last
        #     [ [1, 2] ]                   # append last
        #     [ [1, 2], [] ]               # create new
        #     [ [1, 2], [3] ]              # append last
        #     [ [1, 2], [3] [4] ]          # create new
        #     [ [1, 2], [3] [4, 5] ]       # append last
        #     [ [1, 2], [3, [4, 5]] ]      # pop last and then append to last
        #     [ [1, 2], [3, [4, 5], 6] ]   # append last stack
        #     [ [1, 2, [3, [4, 5], 6] ] ]  # pop last and then append to last

    currentStack: ->
        @stacks[@stacks.length - 1]

    parse: ->
        @parseNext() while @tokens.length > 0
        # console.log @stacks[0]
        return @stacks[0]

    parseNext: ->
        [head, tail...] = @tokens
        @tokens = tail
        {type, value} = head

        scalarTypes = 'string null boolean numeric'.split ' '
        if type in scalarTypes
            @currentStack().push head
        else
            if type is 'token'
                switch value
                    when '['
                        @stacks.push []
                    when ']'
                        throw "unexpected array termination" unless @stacks.length > 1
                        arr = @stacks.pop()
                        @currentStack().push {type: 'array', value: arr}
                    else
                        @currentStack().push head

class RPN
    constructor: ->
        @stack = []
        @dictionary = {}

    startREPL: ->
        @rl = readline.createInterface(process.stdin, process.stdout)
        @rl.setPrompt '> '
        @rl.on 'line', @processLine
        console.log 'Type "help" for a list of commands.'
        @rl.on 'close', @gracefulExit
        @rl.prompt()

    processLine: (line) =>
        @gracefulExit if line is 'q'

        # split input into tokens
        tokens = Tokenizer.tokenize(line)

        # parse tokens into literals
        parser = new Parser(tokens)
        parseStack = parser.parse()

        # execute the parseStack
        @execute parseStack

        @showStack()
        @rl.prompt()

    execute: (parseStack) ->
        for item in parseStack
            literalTypes = "null string boolean numeric array".split ' '
            {type, value} = item
            if type in literalTypes
                @stack.push item
            else
                word = @dictionary[value]
                throw "unsupported word (#{value}) not defined" unless word
                throw "#{word.token} requires stack params with arity (#{word.arity})" unless @validateArity word.arity
                args = @stack.splice(@stack.length - word.arity.length)
                results = word.fn.apply(null, args)
                @stack = @stack.concat results

    showStack: ->
        for item in @stack
            console.log @stackItemToString(item)

    stackItemToString: (item) ->
        {type, value} = item
        if type in "null boolean numeric token".split ' '
            return item.value
        switch item.type
            when 'string'
                return "\"#{item.value}\""
            when 'array'
                strs = value.map (subItem) => @stackItemToString subItem
                return "[ " + strs.join(" ") + " ]"
            else
                return "Unknown stackItem type.  type=#{type}, value=#{value}"

    registerWord: (word) ->
        if word.arity
            word.arity = word.arity.split ' '
        else
            word.arity = []
        @dictionary[word.token] = word

    validateArity: (arity) ->
        arity = arity.reverse()
        return false unless @stack.length >= arity.length
        for type, index in arity
            continue if type is 'any'
            stackItem = @stack[@stack.length - 1 - index]
            unless stackItem.type is type
                console.log "expecting #{type} but got #{stackItem.type} (#{stackItem.value})"
                return false
        return true

    gracefulExit: ->
        console.log ''
        process.exit 0

rpn = new RPN()

rpn.registerWord
    token: '+'
    description: 'Adds 2 numerics together.'
    arity: 'numeric numeric'
    fn: (n1, n2) ->
        [{type: 'numeric', value: n1.value + n2.value}]

rpn.registerWord
    token: '-'
    description: 'Subtract 2 numerics.'
    arity: 'numeric numeric'
    fn: (n1, n2) ->
        [{type: 'numeric', value: n1.value - n2.value}]

rpn.registerWord
    token: '*'
    description: 'Multiply 2 numerics.'
    arity: 'numeric numeric'
    fn: (n1, n2) ->
        [{type: 'numeric', value: n1.value * n2.value}]

rpn.registerWord
    token: '/'
    description: 'Divide 2 numerics.'
    arity: 'numeric numeric'
    fn: (n1, n2) ->
        [{type: 'numeric', value: n1.value * n2.value}]

rpn.registerWord
    token: '%'
    description: 'Modulus 2 numerics.'
    arity: 'numeric numeric'
    fn: (n1, n2) ->
        [{type: 'numeric', value: n1.value % n2.value}]

rpn.registerWord
    token: 'strcat'
    description: 'Concatentate 2 strings.'
    arity: 'string string'
    fn: (str1, str2) ->
        [{type: 'string', value: "#{str1.value}#{str2.value}"}]

rpn.registerWord
    token: 'upcase'
    description: 'The uppercase version of the string.'
    arity: 'string'
    fn: (str1) ->
        [{type: 'string', value: "#{str1.value.toUpperCase()}"}]

rpn.registerWord
    token: 'downcase'
    description: 'The lowercase version of the string.'
    arity: 'string'
    fn: (str1) ->
        [{type: 'string', value: "#{str1.value.toLowerCase()}"}]

rpn.registerWord
    token: 'split'
    description: 'Split a string by a delimeter.'
    arity: 'string string'
    fn: (str1, str2) ->
        parts = str1.value.split str2.value
        [{type: 'array', value: parts.map (part) -> {type: 'string', value: part}}]

rpn.registerWord
    token: 'join'
    description: 'Join array elements into a string using a delimeter.'
    arity: 'array string'
    fn: (arr, delim) ->
        strs = arr.value.map (x) -> x.value.toString()
        str = strs.join delim.value
        [{type: 'string', value: str}]

rpn.registerWord
    token: 'reverse'
    description: 'Reverses the elements in an array.'
    arity: 'array'
    fn: (arr) ->
        [{type: 'array', value: arr.value.reverse()}]

rpn.registerWord
    token: 'num>string'
    description: 'Convert a numeric to a string.'
    arity: 'numeric'
    fn: (num) ->
        [{type: 'string', value: "#{num.value}"}]

rpn.registerWord
    token: 'dup'
    description: 'Duplicates the element at the top of the stack.'
    arity: 'any'
    fn: (x) -> [x, x]

rpn.registerWord
    token: 'swap'
    description: 'Duplicates the element at the top of the stack.'
    arity: 'any any'
    fn: (x, y) -> [y, x]

rpn.registerWord
    token: 'drop'
    description: 'Drops the element at the top of the stack.'
    arity: 'any'
    fn: (x) -> []

rpn.registerWord
    token: 'clear'
    description: 'Clears the content of the stack.'
    arity: ''
    fn: (x) ->
        rpn.stack = []
        return []

rpn.registerWord
    token: '.'
    description: 'Pops the last item off the stack and displays it.'
    arity: 'any'
    fn: (x) ->
        str = JSON.stringify(x.value)
        console.log str
        console.log ''
        return []

rpn.registerWord
    token: 'call'
    description: 'Takes an anonymous function (array) and executes it'
    arity: 'array'
    fn: (func) ->
        rpn.execute func.value
        return []

rpn.registerWord
    token: 'map'
    description: 'Executes the function for each element of the array.'
    arity: 'array array'
    fn: (arr, func) ->
        newArr = arr.value.map (item) ->
            rpn.execute [item]
            rpn.execute func.value
            rpn.stack.pop()
        return [{type: 'array', value: newArr}]

rpn.registerWord
    token: 'help'
    description: 'Shows the available words and their arity.'
    arity: ''
    fn: ->
        for token, word of rpn.dictionary
            console.log "#{token} \t (#{word.arity}) \t #{word.description}"
        console.log ''
        return []

rpn.startREPL()
