lib:
let
  nRecursiveMerge =
    attrList:
    let
      f =
        attrPath:
        lib.zipAttrsWith (
          n: values:
          if lib.tail values == [ ] then
            lib.head values
          else if lib.all lib.isList values then
            lib.unique (lib.concatLists values)
          else if lib.all lib.isString values then
            lib.concatStrings values
          else if lib.all lib.isAttrs values then
            f (attrPath ++ [ n ]) values
          else
            lib.last values
        );
    in
    f [ ] attrList;
in
{
  inherit nRecursiveMerge;
  recursiveMerge =
    a: b:
    nRecursiveMerge [
      a
      b
    ];
}
