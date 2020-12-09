. ./path-gmm.sh


# AUDIO --> FEATURE VECTORS
compute-mfcc-feats \
    --config=conf/mfcc.conf \
    scp:transcriptions/wav.scp \
    ark,scp:transcriptions/feats.ark,transcriptions/feats.scp

# COMPUTE CMVN
compute-cmvn-stats \
    --spk2utt=ark:transcriptions/spk2utt \
    scp:transcriptions/feats.scp \
    ark,scp:transcriptions/cmvn.ark,transcriptions/cmvn.scp

# FEATURE VECTORS + CMVN --> LATTICE
gmm-latgen-faster \
    --max-active=7000 --beam=13.0 --lattice-beam=6.0 --acoustic-scale=0.083333 --allow-partial=true \
    --word-symbol-table=./exp/tri2b/graph/words.txt ./exp/tri2b/final.mdl ./exp/tri2b/graph/HCLG.fst \
    'ark,s,cs:apply-cmvn  --utt2spk=ark:transcriptions/utt2spk scp:transcriptions/cmvn.scp scp:transcriptions/feats.scp ark:- | splice-feats --left-context=3 --right-context=3 ark:- ark:- | transform-feats ./exp/tri2b/final.mat ark:- ark:- |' 'ark:transcriptions/lattices.ark' 

# LATTICE --> BEST PATH THROUGH LATTICE
lattice-best-path \
    --word-symbol-table=exp/tri2b/graph/words.txt \
    ark:transcriptions/lattices.ark \
    ark,t:transcriptions/one-best.tra

# BEST PATH INTERGERS --> BEST PATH WORDS
utils/int2sym.pl -f 2- \
    exp/tri2b/graph/words.txt \
    transcriptions/one-best.tra \
    > transcriptions/one-best-hypothesis.txt