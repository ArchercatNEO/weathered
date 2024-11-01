#!/bin/sh

mkdir -p $out/bin

rustc $src/main.rs \
    --crate-name $pname \
    --crate-type "bin" \
    --edition $edition \
    --emit=dep-info,link \
    --out-dir $out/bin \
    -C embed-bitcode=no \
    -C debuginfo=2 \
    -C prefer-dynamic \
    -C rpath \
    $linkFlags