#lang lean4

def main (args : List String) : IO UInt32 := do
  IO.println (toString args)
  pure 0
