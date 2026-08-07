# Report which expected markers are present in this shell.
#
# Sourced by a benchmarked shell at its first prompt, so it sees exactly the
# state the timing measures. stdout belongs to the harness, so results go to
# a file. Reads .verify-expect, writes "<marker> <0|1>" per line.
#
# Marker kinds: fn, widget, path, fpath, env, bindkey.

_v_out=$ZDOTDIR/.verify-out
_v_keys="$(bindkey)"
: >| $_v_out

for _v_m in ${(f)"$(<$ZDOTDIR/.verify-expect)"}; do
  [[ -z $_v_m || $_v_m == \#* ]] && continue
  _v_kind=${_v_m%%:*}
  _v_name=${_v_m#*:}
  case $_v_kind in
    fn)      _v_st=$(( $+functions[$_v_name] )) ;;
    widget)  _v_st=$(( $+widgets[$_v_name] )) ;;
    path)    _v_st=$(( ${path[(I)*$_v_name*]} > 0 )) ;;
    fpath)   _v_st=$(( ${fpath[(I)*$_v_name*]} > 0 )) ;;
    env)     _v_st=$(( $+parameters[$_v_name] )) ;;
    bindkey) [[ $_v_keys == *$_v_name* ]] && _v_st=1 || _v_st=0 ;;
    *)       _v_st=0 ;;
  esac
  print -r -- "$_v_m $_v_st" >> $_v_out
done
