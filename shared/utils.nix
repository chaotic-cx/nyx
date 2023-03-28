{ lib }:
{
  dropN = n: list: lib.lists.take (builtins.length list - n) list;
}
