# RPN
A simple extendable RPN REPL written in Node.

# Installation

This assumes you already have Node installed.

Install Coffeescript:

    npm install -g coffee-script

Clone the repository and install the dependencies:
    git clone 
    cd rpn
    npm install

# Running

    coffee npm.coffee

Type "help" to get a list of commands:

    + 	         (numeric,numeric) 	 Adds 2 numerics together.
    - 	         (numeric,numeric) 	 Subtract 2 numerics.
    * 	         (numeric,numeric) 	 Multiply 2 numerics.
    / 	         (numeric,numeric) 	 Divide 2 numerics.
    % 	         (numeric,numeric) 	 Modulus 2 numerics.
    strcat 	     (string,string) 	 Concatentate 2 strings.
    upcase 	     (string) 	         The uppercase version of the string.
    downcase 	 (string)         	 The lowercase version of the string.
    split 	     (string,string) 	 Split a string by a delimeter.
    join 	     (array,string) 	 Join array elements into a string using a delimeter.
    reverse 	 (array)         	 Reverses the elements in an array.
    num>string 	 (numeric)         	 Convert a numeric to a string.
    dup 	     (any)             	 Duplicates the element at the top of the stack.
    swap     	 (any,any) 	         Duplicates the element at the top of the stack.
    drop     	 (any) 	             Drops the element at the top of the stack.
    clear 	     () 	             Clears the content of the stack.
    . 	         (any) 	             Pops the last item off the stack and displays it.
    call     	 (array) 	         Takes an anonymous function (array) and executes it
    map     	 (array,array) 	     Executes the function for each element of the array.
    help     	 () 	             Shows the available words and their arity.

# Overview of the language

If you don't already know how a basic RPN calculator works please read some tutorials on that first.

RPN languages (post fix) tend to be extremely compact and powerful.  Here is a snippet that will take a string,
split it on the spaces into an array, reverse the array, convert everythign to uppercase,
and then joins them together with '-'.

    " " split reverse [ upcase ] map "-" join

Here's another example that specifes an array of numbers and squares each element.

    [ 1 2 3 4 5 ] [ dup * ] map

Note the `[ dup * ]`.  It uses the same syntax as the array.  But how can it be a function then.  That's the
beauty there is no difference between arrays and functions.  Arrays are a list of elements and Functions are a
list of instructions.  They are both lists and so they are both stored as arrays.

`1 2 +` and `[ 1 2 + ] call` are basically the same.

## Types

The REPL currently supports null, numerics (ints, floats, 1.25e-7), strings (double quotes only), arrays, and functions.

Arrays use the standard bracket notation but don't use commands to separate.  Also, it is important that the brackets have
whitespace.  `[ 1 2 3 ]` is valid.  `[1 2 3]` is not.  It will think you are trying to call a method called `[1`.

The RPN REPL supports functional operations like `map` using anonymous functions.  Anonymous functions
are **extremely** easy to create in the REPL language.  Anonymous functions are just arrays and arrays
are just anonymous functions.  There's no difference.

# Stack manipulation

It is convenient to move things around the stack sometimes.

`dup` duplicates the last item on the stack.
`swap` swaps the places of the last 2 items on the stack.
`drop` deletes the last item on the stack.
`clear` clears the entire stack so that it's empty.

# Extending the language

Let's start with an example that takes a number and squares it.
    
    rpn.registerWord
        token: 'sq'
        description: 'Square a number.'
        arity: 'numeric'
        fn: (n) ->
            [{type: 'numeric', value: n.value * n.value}]

Ok, let's disect what this means.

`token` is the name of the method (sometimes called a `word` in post fix languages).

`description` is for the user.  It can be any string.  It is only used when displaying the `help`.

`arity` is a list of arguments and their types.  Support types are: `any`, `boolean`, `numeric`, `string`, and `array`.
To make it faster to type just use a string and separate the parameters with spaces.

`fn` is where you define the function.  It is a little bit trickier but not by much:

See the `n` as a function parameter?  When it is passed to your function it will look something like `{type: 'numeric', value: 123}`.

From there you can do whatever you want.

`fn` is required to return an array of items to be pushed back onto the stack.  If you don't want to return anything just return an empty array `[]`.

If you are going to return an `array` as a literal, make sure each element in the array follows the same `type: value` format.

# Enjoy!
