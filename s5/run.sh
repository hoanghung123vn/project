#!/usr/bin/env bash

date --date "7 hour"

. ./cmd.sh
. ./path.sh # Needed for KALDI_ROOT
. ./config.sh # Needed for REC_ROOT and WAV_ROOT

# Check wave file directory
if [ ! -d $WAV_ROOT ]; then
  echo "Cannot find wav directory $WAV_ROOT"
  echo "Please set the WAV_ROOT"
  exit 1;
fi

# Define stage (useful for skipping some stagess)
stage=4
. parse_options.sh || exit 1;

# Define number of parallel jobs
njobs=$(nproc)

# Silence boost factor
boost_silence=1.0

# Setup feature file directory
mfcc="$REC_ROOT/mfcc"
mkdir -p $mfcc

# Setup log file directory
exp="$REC_ROOT/exp"
mkdir -p $exp

# Setup other relevant directories
data="$REC_ROOT/data"
lang="$data/lang"
dict="$data/local/dict"
langtmp="$data/local/lang"
mkdir -p $langtmp
steps="steps"
utils="utils"


# Data preparation
#if [ $stage -le 0 ]; then
#  echo ""
#  echo "Stage 0: Preparing data"
#  rm -rf $data/*
#  local/vn_prepare_data.sh || exit 1
#fi


# Language model preparation
if [ $stage -le 1 ]; then
  echo ""
  echo "Stage 1: Preparing lang"
  rm -rf $lang
  rm -rf $langtmp
#  local/vn_prepare_dict.sh || exit 1
  $utils/prepare_lang.sh --num-sil-states 5 \
     --num-nonsil-states 3 \
     --position-dependent-phones false \
     --share-silence-phones true \
     $dict "<UNK>" $langtmp $lang || exit 1
  local/vn_prepare_grammar.sh || exit 1
fi


# Feature extraction
set_list="train test"
if [ $stage -le 2 ]; then
  echo ""
  echo "Stage 2: Extracting mfcc features"
  rm -rf $mfcc/*

  for x in $set_list; do 
    if [ -d $data/$x ]; then
      $steps/make_mfcc.sh --nj $njobs --cmd "$train_cmd" $data/$x $exp/make_mfcc/$x $mfcc || exit 1
      $steps/compute_cmvn_stats.sh $data/$x $exp/make_mfcc/$x $mfcc || exit 1
    fi
  done
fi


# Training
if [ $stage -le 3 ]; then
  echo ""
  echo "Stage 3: Starting training"
  rm -rf $exp/*

  $steps/train_mono.sh --nj $njobs --cmd "$train_cmd" \
    --boost_silence $boost_silence \
    $data/train $lang $exp/mono0a || exit 1;

  $steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    --boost_silence $boost_silence \
    $data/train $lang $exp/mono0a $exp/mono0a_ali || exit 1;

  $steps/train_deltas.sh --cmd "$train_cmd" \
    --boost_silence $boost_silence \
    2000 10000 $data/train $lang $exp/mono0a_ali $exp/tri1 || exit 1;

  $steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    $data/train $lang $exp/tri1 $exp/tri1_ali || exit 1;

  $steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" \
    2500 15000 $data/train $lang $exp/tri1_ali $exp/tri2b || exit 1;

  $utils/mkgraph.sh $lang $exp/tri2b $exp/tri2b/graph || exit 1;
fi
  
# Decoding
set_list="test"
if [ $stage -le 4 ]; then
  echo ""
  echo "Stage 4: Starting decoding"
  rm -rf $exp/*/decode*

  for x in $set_list; do
    if [ -d "$data/$x" ]; then
      $steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
        $exp/tri2b/graph $data/$x $exp/tri2b/decode_$x || exit 1
    fi
  done
fi

date --date "7 hour"
