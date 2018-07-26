#!/bin/bash -e

SOURCES="$@"

cat > build/script.g <<EOF
fun run_script 0 {
  \$files
  @files 4 vector_init = ;
EOF

M2_CMD="./M2-Planet-gcc"

rm script-data/* || true
for source in $SOURCES ; do
    cp "$source" script-data/
    echo "  files \"/init/$(basename $source)\" strdup vector_push_back ;" >> build/script.g
    M2_CMD="$M2_CMD -f $source"
done

cat >> build/script.g <<EOF
  files "/ram/compiled.m1" m2_compile ;
  files free_vect_of_ptrs ;
  "/ram/compiled.m1" dump_debug ;
}
EOF

M2_CMD="$M2_CMD -o m2_output.m1"
echo $M2_CMD

make
qemu-system-i386 -hda build/boot_asmg.x86 -serial stdio -device isa-debug-exit | ./test/dedump.py 

$M2_CMD

if diff -u dump/ram/compiled.m1 m2_output.m1 ; then
    echo "TEST SUCCESSFUL!"
else
    echo "TEST FAILED..."
fi

exit 0
