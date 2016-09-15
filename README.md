# move-literals - Move string literals

Maybe you're writing a reverse engineering challenge, and you want to obfuscate your code. Maybe you're stuck with a huge legacy codebase in dire need of refactoring. You want to perform a set of operations on source code, but doing it manually is iterative, time consuming and boring. Your IDE isn't as helpful as you would want it to be. Maybe you try using awk or sed and regular expressions, but after a while you need another tool in your toolbox not provided by [regular](https://en.wikipedia.org/wiki/Regular_grammar) or [context-free](https://en.wikipedia.org/wiki/Context-free_grammar) grammars.

Enter [Parsing Expression Grammars](https://en.wikipedia.org/wiki/Parsing_expression_grammar) and [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/).

It's fast, it's elegant, it makes you never want to think about regular expressions ever again.

This repo contains an example of how PEGs can be used. The example finds all string literals in a context where they would be compiled, and replaces them with preprocessor definitions. Why? Well, sometimes you just want to move all your strings around. You don't have to move them, you could just as easy replace them with a rot13, base64 encoded version and force push it to your company's master branch. Try it out!

## dependencies

[Lua](http://lua.org/) (probably/maybe > 5.1)
LPeg

## example

````bash
$ cat example.c
````

````C
#include <stdio.h>

#ifdef __FOO_PLATFORM
#error \
  "unsupported platform"
#endif

int main(int argc, char *argv[]) {
  // char *x = "foobar";
  char *x = "foobarbaz";
  printf("%s\n", x);
  return 42;
}

````

````bash
$ ./move-literals.lua example.c > result.c
$ cat result.c
````

````C
#define STRSYM_FOOBARBAZ \
   "foobarbaz"
#define STRSYM__S_N \
   "%s\n"
#include <stdio.h>

#ifdef __FOO_PLATFORM
#error \
  "unsupported platform"
#endif

int main(int argc, char *argv[]) {
  // char *x = "foobar";
  char *x = STRSYM_FOOBARBAZ;
  printf(STRSYM__S_N, x);
  return 42;
}
````

## dealing with parse errors

move-literals.lua accepts any input, which is not always what you want.

Signalling syntax errors can be done by using match time captures (Cmt) or the function capture operator '/' together with a rule that should never be encountered on valid input:

````lua
  lpeg = require "lpeg"
  P, Cmt, V, S = lpeg.P, lpeg.Cmt, lpeg.V, lpeg.S
  function errfunc(match)
    error("invalid token: "..tostring(match))
  end
  P{
    "tokens";
    space   = S" \t",
    invalid = (1-V"space")^1/errfunc,
    token   = P"foo" + P"bar" + P "baz" + V"invalid",
    tokens  = (V"token" * V"space"^0)^0  * -1
  }:match("foo bar baz woops foo")
````

````lua
  lpeg = require "lpeg"
  P, Cmt, V, S = lpeg.P, lpeg.Cmt, lpeg.V, lpeg.S
  function errfunc(match, pos, cap)
    error(string.format("invalid token at position %d: %s",
      pos-#cap, cap))
  end
  p = P{
    "tokens";
    space   = S" \t",
    invalid = Cmt((1-V"space")^1, errfunc),
    token   = P"foo" + P"bar" + P "baz" + V"invalid",
    tokens  = (V"token" * V"space"^0)^0  * -1
  }:match("foo bar baz woops foo")
````

In more complex grammars, you may need to signal different types of syntax errors. This can be done by adding multiple rules and referencing them with V in places where you can only end up on invalid input.
