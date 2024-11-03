import Lake
open Lake DSL

package "InvertBinaryTree" where
  version := v!"0.1.0"

lean_lib «InvertBinaryTree» where
  -- add library configuration options here

@[default_target]
lean_exe "invertbinarytree" where
  root := `Main
