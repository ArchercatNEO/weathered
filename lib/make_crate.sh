echo $src
echo $out

cd $src

if [[ -n $LIB ]]; then
  echo $LIB
  rustc $LIB --out-dir $out/lib
fi

if [[ -n $BIN ]]; then
  readarray -td ":" BIN <<<"${BIN}"

  for ((i = 0; i < ${#BIN[@]}; i += 1)); do
    bin=${BIN[$i]}
    echo $bin
    rustc $bin --out-dir $out/bin
  done
fi

for example in $EXAMPLE; do
  echo $example
done

for test in $TEST; do
  echo $test
done

for bench in $BENCH; do
  echo $bench
done
