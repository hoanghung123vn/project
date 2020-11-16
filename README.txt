Quick instruction:

1) download vn data

Train set
Test set

2) move to Kaldi vn directory, e.g.,

cd kaldi-trunk/egs/vietnamese2/s5

3) run .path.sh, . cmd.sh

By default, directories data/lang, data/local/lang, exp/, mfcc/ will be created by the recipe in the
Kaldi vn recogniser directory.

4) execute run.sh

./run.sh

4*) we suggest to use the following command to save the main log file

nohup ./run.sh > run.log

5) You can find result at exp/tri2b/decode_*/keyword_scores.txt

