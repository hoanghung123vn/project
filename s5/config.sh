case "$USER" in
"")
  # CHiME Challenge wav root (after unzipping)...
  export WAV_ROOT="/opt/data" 

  # Used by the recogniser for storing data/ exp/ mfcc/ etc
  export REC_ROOT="." 
  echo "Set wav and rec path done"
  ;;
*)
  echo "Please define WAV_ROOT and REC_ROOT for user $USER"
  ;;
esac

