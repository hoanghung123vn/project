#!/bin/bash

# Author Joshua Meyer (2016)

# USAGE:
#    $ kaldi/egs/your-model/your-model-1/gmm-decode.sh
# 
#    This script is meant to demonstrate how an existing GMM-HMM
#    model and its corresponding HCLG graph, build via Kaldi,
#    can be used to decode new audio files.
#    Although this script takes no command line arguments, it assumes
#    the existance of a directory (./transcriptions) and an scp file
#    within that directory (./transcriptions/wav.scp). For more on scp
#    files, consult the official Kaldi documentation.

# INPUT:
#    transcriptions/
#        wav.scp
#
#    config/
#        mfcc.conf
#
#    exp/
#        tri2b/
#            final.mdl
#
#            graph/
#                HCLG.fst
#                words.txt

# OUTPUT:
#    transcriptions/
#        feats.ark
#        feats.scp
#        delta-feats.ark
#        lattices.ark
#        one-best.tra
#        one-best-hypothesis.txt



. ./path-gmm.sh
# make sure you include the path to the gmm bin(s)
# the following two export commands are what my path.sh script contains:
# export PATH=$PWD/utils/:$PWD/../../../src/bin:$PWD/../../../tools/openfst/bin:$PWD/../../../src/fstbin/:$PWD/../../../src/gmmbin/:$PWD/../../../src/featbin/:$PWD/../../../src/lm/:$PWD/../../../src/sgmmbin/:$PWD/../../../src/fgmmbin/:$PWD/../../../src/latbin/:$PWD/../../../src/nnet2bin/:$PWD:$PATH
# export LC_ALL=C

# AUDIO --> FEATURE VECTORS
# compute-mfcc-feats \
#     --config=conf/mfcc.conf \
#     scp:transcriptions/wav.scp \
#     ark,scp:transcriptions/feats.ark,transcriptions/feats.scp



# # add-deltas \
# #     scp:transcriptions/feats.scp \
# #     ark:transcriptions/delta-feats.ark

# compute-cmvn-stats \
#     --spk2utt=ark:transcriptions/spk2utt \
#     scp:transcriptions/feats.scp \
#     ark,scp:transcriptions/cmvn.ark,transcriptions/cmvn.scp

# splice-feats --left-context=3 --right-context=3 \
#     scp:transcriptions/feats.scp \
#     ark,scp:transcriptions/splice-feats.ark,transcriptions/splice-feats.scp


# transform-feats \
#     ./exp/tri2b/final.mat \
#     scp:transcriptions/splice-feats.scp \
#     ark,scp:transcriptions/lda-feats.ark,transcriptions/lda-feats.scp

# # TRAINED GMM-HMM + FEATURE VECTORS --> LATTICE
# gmm-latgen-faster \
#     --max-active=7000 --beam=13.0 --lattice-beam=6.0 --acoustic-scale=0.083333 --allow-partial=true \
#     --word-symbol-table=exp/tri2b/graph/words.txt \
#     exp/tri2b/final.mdl \
#     exp/tri2b/graph/HCLG.fst \
#     ark:transcriptions/lda-feats.ark \
#     ark,t:transcriptions/lattices.ark

# # LATTICE --> BEST PATH THROUGH LATTICE
# lattice-best-path \
#     --word-symbol-table=exp/tri2b/graph/words.txt \
#     ark:transcriptions/lattices.ark \
#     ark,t:transcriptions/one-best.tra

# # BEST PATH INTERGERS --> BEST PATH WORDS
# utils/int2sym.pl -f 2- \
#     exp/tri2b/graph/words.txt \
#     transcriptions/one-best.tra \
#     > transcriptions/one-best-hypothesis.txt

gmm-latgen-faster \
    --max-active=7000 --beam=13.0 --lattice-beam=6.0 --acoustic-scale=0.083333 --allow-partial=true \
    --word-symbol-table=./exp/tri2b/graph/words.txt ./exp/tri2b/final.mdl ./exp/tri2b/graph/HCLG.fst 'ark,s,cs:apply-cmvn  --utt2spk=ark:transcriptions/utt2spk scp:transcriptions/cmvn.scp scp:transcriptions/feats.scp ark:- | splice-feats --left-context=3 --right-context=3 ark:- ark:- | transform-feats ./exp/tri2b/final.mat ark:- ark:- |' 'ark:|gzip -c > ./exp/tri2b/decode_test/lat.1.gz' 
