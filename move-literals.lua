#!/usr/bin/env lua
-- vim: set tabstop=2 shiftwidth=2 expandtab cc=80:

-- Writes a transformation of a C source code file where all the string
-- literals have been moved to the beginning of the code, to stdout.
--
-- Requires lua (probably 5.2 or 5.3) and LPeg

lpeg = require"lpeg"

-- minimum length of string to be replaced
MINLEN = 4

-- symbol prefix for #define statements
SYMPREFIX = "STRSYM_"

function build_parser(syms)
  local P  = lpeg.P
  local V  = lpeg.V
  local S  = lpeg.S
  local B  = lpeg.B
  local C  = lpeg.C
  local Cs = lpeg.Cs
  local Ct = lpeg.Ct

  local function cap(str)
    if #str >= MINLEN then
      local label = SYMPREFIX..str:gsub("%W", "_"):upper()
      syms[label] = str
      return label
    else
      return "\""..str.."\""
    end
  end

  -- NB: currently, this grammar captures all tokens to a table. Tokens
  -- that are not comments, preprocessor macros or string literals are one
  -- byte. That probably means a lot of overhead and can most likely be
  -- improved on. It shouldn't matter that much though, unless your source
  -- files are huge.
  return P{
    "code";
    literal  = P"\"" * Cs((((P"\\"*P(1)) + (1-S"\n\r\""))^0)/cap) * P"\"",
    newline  = (P"\r"^-1 * P"\n") + -1,
    endmacro = -B"\\" * V"newline",
    macrodir = P"#define" + P"#error" + P"#warning" + P"#undef" + P"#ifdef" +
               P"#ifndef" + P"#if" + P"#else" + P"#elif" + P"#endif" +
               P"#pragma",
    macro    = V"macrodir"* (1-V"endmacro")^0 * V"endmacro",
    scomment = P"//" * (1-V"newline")^0 * V"newline",
    mcomment = P"/*" * (1-P"*/")^0 * P"*/",
    code     = Ct((C(V"mcomment" + V"scomment" + V"macro") + V"literal" +
               C(P(1)))^0),
  }
end

function load_data(file)
  f, err = io.open(file, "rb")
  if err ~= nil then
    error(err)
  end
  data = f:read("*a")
  f:close()
  if data == nil then
    error("error reading data")
  end
  return data
end

if arg[1] == nil then
  error("usage: move-literals.lua <in-file>")
end

local data = load_data(arg[1])
local syms = {}
local p = build_parser(syms)
res = p:match(data)
for label, str in pairs(syms) do
  io.write(string.format("#define %s \\\n   \"%s\"\n", label, str))
end
io.write(table.concat(res))
