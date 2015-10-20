REBOL [
    Title: "Structure matching and rewriting engine"
    File: %rewrite.r
    Purpose: {
        Implements a structure matching and rewriting engine using
        PARSE.
    }
    Author: "Gabriele Santilli"
    EMail: giesse@rebol.it
    License: {
        Copyright (c) 2006, Gabriele Santilli
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions
        are met:

        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer. 
          
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials provided
          with the distribution. 

        * The name of Gabriele Santilli may not be used to endorse or
          promote products derived from this software without specific
          prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
        "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
        LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
        FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
        COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
        INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
        BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
        LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
        ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
        POSSIBILITY OF SUCH DAMAGE.
    }
    Date: 17-May-2006
    Version: 1.2.1
    History: [
        17-May-2006 1.1.0 "History start"
        17-May-2006 1.2.1 "First version"
    ]
]

either system/version > 2.100.0 [; R3

    ; Brett Handley: Create R3 version of match to guard the INTO.

    match: func [
        "Match a pattern over data"
        data [block! string!] "Data to match the pattern to"
        rule [block!] "PARSE rule to use as pattern"
        /local
        result recurse
    ] [
        result: false
        recurse: either block? data [[
                some [
                    rule (result: true)
                    |
                    and any-block! into recurse
                    |
                    skip
                ]
            ]] [[
                some [
                    rule (result: true)
                    |
                    skip
                ]
            ]]
        parse data recurse
        result
    ]

] [

    match: func [
        "Match a pattern over data"
        data [block! string!] "Data to match the pattern to"
        rule [block!] "PARSE rule to use as pattern"
        /local
        result recurse
    ] [
        result: false
        recurse: either block? data [[
                some [
                    rule (result: true)
                    |
                    into recurse
                    |
                    skip
                ]
            ]] [[
                some [
                    rule (result: true)
                    |
                    skip
                ]
            ]]
        parse data recurse
        result
    ]

]

rewrite: func [
    "Apply a list of rewrite rules to data"
    data [block! string!] "Data to change"
    rules [block!] "List of rewrite rules"
    /trace "Trace rewriting process (for debugging)"
    /local
    rules* prod mk1 mk2
] [
    if empty? rules [return data]
    rules*: make block! 16
    foreach [pattern production] rules [
        insert insert/only insert/only tail rules* pattern make paren! compose/only [
            prod: compose/deep (production)
        ] '|
    ]
    remove back tail rules*
    until [
        if trace [probe data ask "? "]
        not match data [mk1: rules* mk2: (change/part mk1 prod mk2) :mk1]
    ]
    data
]