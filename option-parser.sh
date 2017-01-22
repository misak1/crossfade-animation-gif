#!/bin/bash
# コマンドラインオプション解析スクリプト
# 解析できるオプションは以下の3タイプ：
#   single:   -XX
#   pair:     -XX YY
#   floating: YY
# これらのオプションが，いくつでも，どんな順で並んでいてもよい
# usage:
#   source ~/lib/bash/option-parser.sh
#   set_single_opts AAA BBB # single (-XX) オプションを指定
#   parse_opts "$@" # パース
# pair (-XX YY) オプションは，解析(parse_opts)後 `opt XX` で YY を取り出せる
# single (-XX) オプションは， `opt XX` で 1 が返る (オプションで指定されていなければ空白)
# single (-XX) のオプションを使う場合は， parse_opts を呼び出す前に set_single_opts を使う必要がある
# floating (YY) オプションは，配列 fargs に YY が格納される
# NOTE opt でコマンドライン引数にないオプションを取得しようとした場合 空白 "" が返る
# NOTE オプション中の記号はすべてアンダーライン(_)と同一視される
# NOTE -- 以降はすべて fargs に格納される（i.e. floating (YY) オプションとみなされる）

# オプション名を内部名に変換する
function option_name_conv() # OPTION_NAME
{
  printf -- "$1" | sed 's/[^a-zA-Z0-9_]/_/g'
}

# OPTION_NAME の内容を取り出す
# (何も格納されない場合は DEFAULT_VALUE が得られる)
function opt() # OPTION_NAME [DEFAULT_VALUE]
{
  eval "local res=\"\$commandline_option_`option_name_conv $1`\""
  if [ "$res" == "" ] && [ "$2" != "" ]; then printf -- "$2"; fi
  printf -- "$res"
}

# 単体で使われるオプション(-XX タイプ)を指定する
function set_single_opts() # OPTION_NAME [OPTION_NAME [OPTION_NAME] ...]
{
  local N=$#
  for ((i=0; i<$N; i++)); do
    eval "commandline_option_single_`option_name_conv $1`=1"
    shift
  done
}

# 使用する変数を指定する
function using_opts() # OPTION_NAME [OPTION_NAME [OPTION_NAME] ...]
{
  local N=$#
  for ((i=0; i<$N; i++)); do
    eval "commandline_option_used_`option_name_conv $1`=1"
    shift
  done
}

# 使われていないオプション(-XX YY タイプのみ)の一覧を出力する
# 使われていないオプションがあれば 1, なければ 0 を返す
function check_unused_opts()
{
  local unused_opt_exists=0
  for on in ${commandline_option_list[@]};do
    eval "local used=\$commandline_option_used_`option_name_conv $on`"
    if [ $used -eq 0 ];then
      unused_opt_exists=1
      eval "res=\"\$commandline_option_`option_name_conv $on`\""
      echo "unused option: -$on $res"
    fi
  done
  return $unused_opt_exists
}

# すべての -XX YY タイプのオプションを出力
function list_options()
{
  for on in ${commandline_option_list[@]};do
    eval "local res=\"\$commandline_option_`option_name_conv $on`\""
    echo "$on=$res"
  done
}

function __register_opt()  # optname optcontents
{
  local optname=$1
  local ioptname=`option_name_conv $1`
  local optcontents=$2
  local duplicated=0
  if [ $# -ne 2 ];then echo "invalid options for __register_opt! (bug!)"; fi
  eval "local oldcontents=\"\$commandline_option_$ioptname\""
  if [ "$oldcontents" != "" ]; then
    echo "warning: option -$optname is redefined (note: internal name the option is -$ioptname)"
    duplicated=1
  fi
  eval "commandline_option_$ioptname='$optcontents'"
  eval "commandline_option_used_$ioptname=0"
  if [ $duplicated -ne 1 ];then
    commandline_option_list[$commandline_option_count]=$optname
    commandline_option_count=$((commandline_option_count+1))
  fi
}

function __register_fargs()  # optcontents
{
  if [ $# -ne 1 ];then echo "invalid options for __register_fargs! (bug!)"; fi
  fargs[$fargs_count]="$1"
  fargs_count=$((fargs_count+1))
}

function parse_opts()
{
  local optname=''
  local commandline_option_count=0
  local fargs_count=0
  local flag_ign_opt=0
  local N=$#
  for ((i=0; i<$N; i++)); do
    if [ "$optname" == "" ];then
      if [ $flag_ign_opt -eq 1 ];then
        __register_fargs "$1"
      elif [ "$1" == "--" ];then
        flag_ign_opt=1
      elif [ "`printf -- $1|sed 's/^\-.\+//g'`" == "" ];then
        optname="`printf -- $1|sed 's/^\-//g'`"
        eval "local is_single=\$commandline_option_single_`option_name_conv $optname`"
        if [ "$is_single" == "1" ];then
          __register_opt $optname 1
          optname=""
        fi
      else
        __register_fargs "$1"
      fi
    else
      local optcontents=$1
      __register_opt $optname "$optcontents"
      optname=""
    fi
    shift
  done
  if [ "$optname" != "" ];then
    echo "incomplete option: -$optname"
    exit 1
  fi
}