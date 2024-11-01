#!/bin/sh

mkdir -p $out/lib

rustc $src/lib.rs \
    --crate-name $pname \
    --crate-type "dylib" \
    --edition $edition \
    --out-dir $out/lib \
    --emit=dep-info,link \
    -C embed-bitcode=no \
    -C debuginfo=2 \
    -C prefer-dynamic \
    $linkFlags