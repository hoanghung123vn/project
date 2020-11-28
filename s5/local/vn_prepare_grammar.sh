#!/usr/bin/env bash

echo "Preparing grammar for test"

. ./config.sh # Needed for REC_ROOT and WAV_ROOT
. $KALDI_ROOT/tools/env.sh

# Setup relevant folders
localdir="$REC_ROOT/data/local"
input="$REC_ROOT/input"
lang="$REC_ROOT/data/lang"
rm -rf $localdir/tmp
mkdir $localdir/tmp

# Create FST grammar for the GRID
echo "Make lm.arpa"
ngram-count -order 4 -write-vocab $input/vocab2.txt -wbdiscount -text $input/corpus2.txt -lm $localdir/tmp/lm.arpa sort

echo "Make G.fst"
arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang/words.txt $localdir/tmp/lm.arpa $lang/G.fst || exit 1

# Draw the FST
#echo "fstdraw --isymbols=$lang/words.txt --osymbols=$lang/words.txt $lang/G.fst | dot -Tps > local/G.ps"

echo "--> Grammar preparation succeeded"
exit 0
