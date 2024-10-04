#!/usr/bin/env bash

# fix segmentation fault reported in https://github.com/k2-fsa/icefall/issues/674
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python

set -eou pipefail

nj=15
stage=0
stop_stage=100

# Path to your local myvoice_train.jsonl.gz file
local_data_path="/content/drive/MyDrive/ColabData/KWS/kws_create_dataset/myvoice_train.jsonl.gz"

dl_dir=$PWD/download
lang_char_dir=data/lang_char

. shared/parse_options.sh || exit 1

# All files generated by this script are saved in "data".
# You can safely remove "data" and rerun this script to regenerate it.
mkdir -p data

log() {
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}

log "dl_dir: $dl_dir"

if [ $stage -le 0 ] && [ $stop_stage -ge 0 ]; then
  log "Stage 0: Copy local data and download musan if needed"
  mkdir -p data/manifests
  cp $local_data_path data/manifests/cuts_train.jsonl.gz
  cp /content/drive/MyDrive/ColabData/KWS/kws_create_dataset/*.wav /content/icefall/egs/wenetspeech/ASR/data/

  if [ ! -d $dl_dir/musan ]; then
    log "Downloading musan dataset"
    lhotse download musan $dl_dir
  fi
fi

if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
  log "Stage 1: Prepare musan manifest"
  mkdir -p data/manifests
  lhotse prepare musan $dl_dir/musan data/manifests
fi

if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
  log "Stage 2: Preprocess local manifest"
  if [ ! -f data/fbank/.preprocess_complete ]; then
    python3 ./local/preprocess_wenetspeech.py --perturb-speed True
    touch data/fbank/.preprocess_complete
  fi
fi

if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
  log "Stage 3: Combine features"
  if [ ! -f data/fbank/cuts_train.jsonl.gz ]; then
    cp data/manifests/cuts_train.jsonl.gz data/fbank/cuts_train.jsonl.gz
  fi
fi

# Add any additional stages you need for your specific use case

log "Data preparation completed."
