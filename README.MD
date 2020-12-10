# Xây dựng hệ thống nhận dạng giọng nói trên bộ công cụ Kaldi

## Hướng dẫn cài đặt thư viện Kaldi
Kaldi được hỗ trợ cả trên các hệ thống UNIX và Window nhưng trên Window ít được hỗ trợ cũng như tiềm ẩn nhiều lỗi hơn. Vậy nên ở đây chúng ta khuyến nghị sử dụng môi trường UNIX hơn. Để cài đặt Kaldi có nhiều cách, sử dụng trình đóng gói môi trường chạy Docker cho phép ta cài đặt nhanh Kaldi chỉ với vài bước đơn giản, không phụ thuộc hệ điều hành cũng như ít xảy ra lỗi (hầu như không có).
1. Yêu cầu tiên quyết
- Môi trường Window/MacOS/Linux.
- Có kiến thức về Docker.
2. Cài đặt Docker
- Hướng dẫn cài đặt Docker cho bất kỳ hệ điều hành nào có sẵn trên [tài liệu](https://docs.docker.com/) của Docker.
3. Chạy Kaldi trên Docker
- Images Kaldi có sẵn trên [Docker Hub](https://hub.docker.com/r/kaldiasr/kaldi) với 2 phiên bản dùng CPU và GPU. Trong hướng dẫn này, để đơn giản chúng ta sử dụng phiên bản CPU.
- Image Kaldi có file Dockerfile như sau:

```Dockerfile
FROM debian:9.8
LABEL maintainer="mdoulaty@gmail.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        make \
        automake \
        autoconf \
        bzip2 \
        unzip \
        wget \
        sox \
        libtool \
        git \
        subversion \
        python2.7 \
        python3 \
        zlib1g-dev \
        ca-certificates \
        gfortran \
        patch \
        ffmpeg \
	vim && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python2.7 /usr/bin/python

RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /opt/kaldi && \
    cd /opt/kaldi/tools && \
    ./extras/install_mkl.sh && \
    make -j $(nproc) && \
    cd /opt/kaldi/src && \
    ./configure --shared && \
    make depend -j $(nproc) && \
    make -j $(nproc) && \
    find /opt/kaldi -type f \( -name "*.o" -o -name "*.la" -o -name "*.a" \) -exec rm {} \; && \
    find /opt/intel -type f -name "*.a" -exec rm {} \; && \
    find /opt/intel -type f -regex '.*\(_mc.?\|_mic\|_thread\|_ilp64\)\.so' -exec rm {} \; && \
    rm -rf /opt/kaldi/.git
WORKDIR /opt/kaldi/
```
- Lưu ý khi chạy container chúng ta sẽ mount ổ đĩa bên ngoài máy chứa thư mục công thức với thư mục chứa công thức trong container của chúng ta. Đồng thời mở port 8080 để sau này export model ra một service.
- Có thể tự build image ở máy của bạn hoặc sử dụng image chính thức của Kaldi bằng câu lệnh sau:
```sh
docker run -it -v path/to/recipe:/opt/kaldi/egs/vietnamese2 -p 8080:8080 --name=my-kaldi kaldiasr/kaldi:latest
```

4. Làm quen với Kaldi
- Thư viện Kaldi có cấu trúc bao gồm các thư mục con bên trong như `egs`, `src`, `tools`, `misc`, và `windows`,.. Thư mục `egs` chứa các ví dụ trong đó có các công thức sử dụng được xây dựng sẵn trên các bộ dữ liệu khác nhau đã được thử nghiệm trên Kaldi; thư mục `src` chứa mã nguồn của thư viện Kaldi; thư mục tools chứa các công cụ bên ngoài cần thiết cho các quá trình xây dựng model cũng như các thư viện toán học; thư mục `misc` chứa nguồn một số bài báo về kaldi, các kịch bản chuyển đổi từ HTK sang Kaldi; thư mục `window` chứa hướng dẫn dành cho Window. Chúng ta quan tâm nhất đến thư mục `egs`, nơi chúng ta sẽ xây dựng model của riêng mình. Bên trong thư mục `egs` sẽ có các thư mục con `s3`, `s4`, `s5`,.. chính là các phiên bản của các công thức. Các thành phần chính của một công thức thường bao gồm: file `run.sh` chứa kịch bản sẽ được thực thi cho toàn bộ quá trình train và test; file `path.sh` thêm các thư mục cần thiết vào path; file `cmd.sh` chỉ định các lệnh nào sẽ được thực thi; thư mục `data` chứa dữ liệu cần thiêt cho quá trình xậy dựng mô hình âm thanh và mô hình ngôn ngữ; thư mục `local` chứa các kịch bản thường chỉ dành riêng cho công thức đó như các bước chuẩn bị dữ liệu, đánh giá; thư mục `conf` chứa các cấu hình trong việc tạo các đặc trưng, giải mã,..; các thư mục `utils` và `steps` được lấy liên kết đến ví dụ `wsj` là các tiện ích hữu dụng và các bước thường được dùng đến trong quá trình train và test.
## Hướng dẫn training Model và kiểm thử kết quả nhận dạng giọng nói bằng Kaldi
Thực hiện các bước sau để chuẩn bị cho quá trình training:
- Cài đặt srilm:
```sh
$ cd kaldi-trunk/tools
$ wget -O srilm.tgz https://raw.githubusercontent.com/denizyuret/nlpcourse/master/download/srilm-1.7.0.tgz
$ ./install_srilm.sh
...
Installation of SRILM finished successfully
Please source the tools/env.sh in your path.sh to enable it
```
- Di chuyển đến thư mục chứa công thức
```sh
cd egs/vietnamese2/s5
```
- Tạo thư mục `wav` trong thư mục `s5` để chứa dữ liệu file âm thanh dùng cho việc training. Do chúng ta đã mount thư mục công thức ra ngoài ổ đĩa máy, ta có thể dễ dàng tải dữ liệu về chuyển vào ổ đĩa máy, trong container sẽ tự nhận những thay đổi này. Lưu ý cấu trúc thư mục trong thư mục `wav` bao gồm 2 thư mục con là `train` dành cho mục đích `train` và `test` dành cho mục đích `test`.

- Tạo link đến 2 thư mục `utils` và `steps`.
```sh
ln -s ../../wsj/s5/utils utils
ln -s ../../wsj/s5/utils steps
```
- Tạo file `cmd.sh` có nội dung như sau
```sh
export train_cmd="run.pl"
export decode_cmd="run.pl"
export mkgraph_cmd="run.pl"
# Có thể thay đổi run.pl thành queue.pl nếu máy bạn sử dụng hàng đợi
```

- Tạo file `path.sh` để thêm các đường dẫn cần thiết vào path
```sh
export KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C # Chỉ ra thứ tự sắp xếp
```
- Tạo file `config.sh` để đặt đường dẫn cho thư mục gốc của Kaldi và thư mục chứa các file âm thanh: 
```sh
case "$USER" in
"")
  # Wav root (after unzipping)...
  export WAV_ROOT="./wav" 

  # Used by the recogniser for storing data/ exp/ mfcc/ etc
  export REC_ROOT="." 
  echo "Set wav and rec path done"
  ;;
*)
  echo "Please define WAV_ROOT and REC_ROOT for user $USER"
  ;;
esac
```

- Tạo thư mục input chứa các file đầu vào cần cho các bước chuẩn bị là `corpus.txt`, `vocab.txt`, `lexicon.txt`, các file này thường khá lớn, xem kỹ hơn ở link github bên dưới.

- Tạo thư mục `conf` chứa các file cấu hình cho việc tạo đặc trưng và giải mã, chứa các file `mfcc.conf`:
```conf
--use-energy=false   # only non-default option.
--sample-frequency=16000 #  sampled at 16kHz
```
và file `decode.config`: 
```config
beam=13.0
lattice_beam=6.0
max_active=7000
acwt=0.083333
```

- Tạo thư mục local chứa các bước chuẩn bị cho công thức của chúng ta, file `vn_prepare_dict.sh` dùng để chuẩn bị từ điển cho bộ dữ liệu: 

```sh
echo "Preparing dictionary"

. ./config.sh # Needed for REC_ROOT and WAV_ROOT

# Prepare relevant folders
dict="$REC_ROOT/data/local/dict"
mkdir -p $dict

utils="utils"

# Copy lexicon
lexicon="input/lexicon.txt" # phone models
cp $lexicon $dict/lexicon.txt

# Generate phone list
sil="SIL"
phone_list="$dict/phone.list" 
awk '{for (n=2;n<=NF;n++)print $n;}' $lexicon | sort -u > $phone_list
echo $sil >> $phone_list

# Create phone lists 
grep -v -w $sil $phone_list > $dict/nonsilence_phones.txt
echo $sil > $dict/silence_phones.txt
echo $sil > $dict/optional_silence.txt

# list of "extra questions"-- empty; we don't  have things like tone or 
# word-positions or stress markings.
touch $dict/extra_questions.txt

echo "-->Dictionary preparation succeeded"
exit 0
```

- File `vn_prepare_grammar.sh` dùng để tạo mô hình ngôn ngữ bằng thư viện n-gram:

```sh
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

echo "--> Grammar preparation succeeded"
exit 0
```

- Link file `local/score.sh` đến file `../steps/score_kaldi.sh` dùng để cho điểm kết quả giải mã.

```sh
ln -s ../steps/score_kaldi.sh score.sh
```
- Tạo thư mục `data` chứa 2 thư mục con là `train` và `test` để tạo mô hình âm thanh của mỗi tập, cấu trúc 2 thư mục khá giống nhau, tùy vào nội dung của dữ liệu là `train` hay `test`. Đối với tập `train`, đầu tiên tạo file `text` có dạng như sau `utt_id transcript`, file `spk2utt` có dạng `speaker_id utt_id`, file `utt2spk` có dạng `utt_id speaker_id`, file `wav.scp` có dạng `utt_id absolute_path_to_utt`. 2 file `spk2utt` và `utt2spk` có thể được tạo qua lại bằng câu lệnh `utils/spk2utt_to_utt2spk.pl` và `utils/utt2spk_to_spk2utt.pl`, tất cả các file này đều có sẵn trong thư mục `data/train` trên github. Đối với thư mục `test` cũng chuẩn bị tương tự. Trong thư mục scripts có chứa một số script để có thể tạo ra được file `utt2spk` và `wav.scp` nhưng phải chuẩn bị dữ liệu có định dạng như sau: trong thư mục `train` tạo các thư mục con có tên là `speaker_id`, trong mỗi thư mục con đó thì các file dữ liệu âm thanh có tên `utt_id.wav`.

- Cuối cùng là tạo file run.sh là đầu vào của quá trình train và test, chứa tất cả các bước cần thực hiện, bao gồm Thiết lập các đường dẫn ban đầu -> Đặt các tham số -> Chuẩn bị mô hình ngôn ngữ -> Trích xuất các đặc trưng -> Training mono -> Align mono -> Training deltas -> Align deltas -> Train LDA MLTT -> Tạo đồ thị giải mã -> Giải mã, có nội dung như sau: 
```sh
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
stage=0
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

# Language model preparation
if [ $stage -le 1 ]; then
  echo ""
  echo "Stage 1: Preparing lang"
  rm -rf $lang
  rm -rf $langtmp
 local/vn_prepare_dict.sh || exit 1
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

```

- Đối với bộ dữ liệu train khoảng 25h đồng hồ thì thời gian chạy mất khoảng 2h đồng hồ với máy tính cá nhân thông thường 4 CPU, 4G RAM.

- Sau khi chạy xong, nếu không có bất cứ lỗi này thì kết quả giải mã cho ta thấy được WER (mật độ lỗi từ) ở fle `best_wer` trong thư mục `exp/tri2b/decode_test/score_kaldi`.

Tất cả mã nguồn của quá trình train nằm trên [github](https://github.com/hoanghung123vn/project) của tác giả.

## Đóng gói Model dưới dạng một dịch vụ
- Mô hình chúng ta xây dựng dựa trên GMM nên chúng ta sẽ dùng mô hình GMM để giải mã. Tất cả những gì chúng ta cần chính là đầu ra của quá trình train: 
```sh
# INPUT:
#    transcriptions/
#        wav.scp
#        spk2utt
#        utt2spk
#    conf/
#        mfcc.conf
#
#    exp/
#        tri2b/
#            final.mdl
#
#            graph/
#                HCLG.fst
#                words.txt
```
- Thêm path của gmmbin vào path của chúng ta bằng file `path-gmm.sh`: 
```sh
export KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnet2bin/:$PWD:$PATH
export LC_ALL=C
```

- Sử dụng file gmm-decode.sh để tiến hành giải mã với một file âm thanh bất kỳ: 
```sh
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
```
Kết quả nhận được của quá trình giải mã nằm trong file `transcriptions/one-best-hypothesis.txt`.

- Để đóng gói hệ thống nhận dạng dưới dạng dịch vụ, chúng ta sử dụng framework Spring boot, tạo API khi được gọi sẽ chạy lệnh giải mã này và trả ra kết quả.