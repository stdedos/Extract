#!/bin/bash
#
# Extract common file formats effortlessly
#
# Author: xVoLAnD <xvoland@gmail.com>
# Author: Stdedos <133706+stdedos@users.noreply.github.com>

in_temp_exp_disable=999
status_failure=1
status_unknown_archive=120

in_temp() {
  set -Eeuo pipefail

  # If we force in-dir extraction, don't nest invocations
  case ${2:-} in
    '') :;;
    *[!0-9]*) >&2 echo "${FUNCNAME[0]}: Invalid second argument, ignoring! ($2)" ;;
    "${in_temp_exp_disable}") echo . ; return ;;
    *) :;;
  esac

  in_dir="$(mktemp -dp . "${n}-XXXXX")"
  >&2 echo "Copying (hardlink) '$n' in '${in_dir}/$n'"

  cp -l "$1" "${in_dir}/$n"
  echo "${in_dir}"
}

7z_cross_platform() {
  # stdbuf -e0 -i0 -o0: We are piping the command;
  #                     don't let this ruin our output
  local STDBUF=(stdbuf -e0 -i0 -o0)

  command -V "${STDBUF[0]}" &> /dev/null || STDBUF=()

  if command -V 7zr &> /dev/null; then
    "${STDBUF[@]}" 7zr x "$1"
  elif command -V 7za &> /dev/null; then
    "${STDBUF[@]}" 7za x "$1"
  elif command -V 7z &> /dev/null; then
    "${STDBUF[@]}" 7z x "$1"
  else
    echo "Could not find p7zip!"
    (exit 126)
  fi
}

extractable_extesions() {
  grep -oP '(?<=\*\.)[\w.]+' "$0" | sort | uniq | tr '\n' '|' | sed 's/.$//'
  [ -t 1 ] || echo
}

usage() {
  {
    echo "${name}: magically extract any kind of archive"
    {
      printf "Includes: "
      extractable_extesions | sed 's/|/, /g'
    } | fold --space | sed -e '1s/^/  /g' -e '1 ! s/^/    /g'
    echo "  ... and many more, if \`p7zip\` supports them ;-)"
    echo
    echo "Usage:"
    echo "  ${name} -h|--help"
    echo "  ${name} [-v|-V] [-k|-K] [-d/-D] path/file_name_1.ext ..."
    echo
    echo "  -v/-V: Toggle verbose on (v) or off (V)"
    echo "  -k/-K: Toggle force-keeping the archive on (k) or off (k)"
    echo "  -d/-D: Toggle force-extract inside a directory on (k) or off (k)"
    echo
    echo "  You can mix those flags with normal arguments, e.g.:"
    echo "    ${name} -v archive-1.tgz -V -k archive-2.tgz -d archive-3.tgz ..."
    echo "  and they will apply from the next command onwards"
    echo "  i.e. if you want to apply them for the whole session, list them first"
    echo
    echo "  Collated arguments (e.g. -vK) are not accepted, and this is an error."
    echo "  If you insist that it is a filename (there is already a check), prepend it with \`./\`"
    echo
    echo "(Note that you may want to \`cd\` to the directory you want to extract to!)"
    echo
    echo "Exit Code:"
    echo "  0     - all okay"
    echo "  1-123 - # of input files / archives not processed"
    echo "  124   - # of input files / archives not processed or more*"
    echo "  125   - argument parsing error"
    echo "  126   - show help"
    echo "  127   - (reserved)"
  } >&2
}

function extract {
  local EXIT_CODE=0
  local VERBOSE=1
  local KEEP=0
  local FORCE_DIR="${FORCE_DIR:-1}"
  local in_dir
  local name
  local status
  local msg
  local -a VERBOSE_FLAG
  local -a KEEP_FLAG

  name="${FUNCNAME[0]}"
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && command -V perl &> /dev/null ; then
    name="$(perl -pe "s#($(tr ':' '|' <<< "${PATH}"))/##g" <<< "$0")"
  fi

  if [ -z "$1" ] || [[ "$*" =~ (^|\s)(-h|--help)(\s|$) ]] ; then
    # display usage if no parameters given or -h/--help at arguments
    usage
    return 126
  fi

  for n ; do
    VERBOSE_FLAG=()
    KEEP_FLAG=()
    in_dir=
    status=0

    case $n in
      -v) VERBOSE=0     ; continue ;;
      -V) VERBOSE=1     ; continue ;;
      -k) KEEP=0        ; continue ;;
      -K) KEEP=1        ; continue ;;
      -d) FORCE_DIR=0   ; continue ;;
      -D) FORCE_DIR=1   ; continue ;;
      -*) if [ ! -f "$n" ] ; then
            >&2 echo "Argument '$1' not recognized, and it's not a filename!"
            return 125
          fi
      ;;
      *)  ;;
    esac

    if [ ! -f "$n" ] ; then
      echo "'$n' - file does not exist" >&2
      EXIT_CODE="$((EXIT_CODE + 1))"
      continue
    fi

    if [ "${FORCE_DIR}" -eq 0 ] ; then
      if ! in_dir="$(in_temp "$n" "${FORCE_DIR}")" ; then
        echo "Failed to prepare '$n' for extraction!" >&2
      fi
      if ! (cd "${in_dir}" && FORCE_DIR="${in_temp_exp_disable}" extract "$n") ; then
        EXIT_CODE="$((EXIT_CODE + 1))"
      fi

      echo "Removing '${in_dir}/${n}' hardlink" >&2
      rm "${in_dir}/${n}" || echo "^^ FAILED!" >&2

      continue
    fi
    if [ "${VERBOSE}" -eq 1 ] ; then
      echo "===> Extracting: $n <===" >&2
    fi

    case "${n%,}" in
      *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                              test "${VERBOSE}" -eq 0 && VERBOSE_FLAG=(v)
                              tar "${VERBOSE_FLAG[*]}"xf "$n"       ;;
      *.lzma)                 unlzma "$n"      ;;
      *.bz2)                  test "${KEEP}" -eq 0 && KEEP_FLAG=(-k)
                              bunzip2 "${KEEP_FLAG[@]}" "$n"     ;;
      *.cbr|*.rar)            unrar x -ad "$n" ;;
      *.gz)                   test "${KEEP}" -eq 0 && KEEP_FLAG=(-k)
                              gunzip "${KEEP_FLAG[@]}" "$n"      ;;
      *.docx|*.xlsx)
        if ! in_dir="$(in_temp "$n" "${FORCE_DIR}")" ; then
          echo "Failed to prepare '$n' for extraction!" >&2
        fi
      ;&
      *.cbz|*.epub|*.zip|*.whl|*.war)
        # We test quiet instead
        test "${VERBOSE}" -eq 1 && VERBOSE_FLAG=(-q)
        (
          if [ -n "${in_dir}" ] ; then
            cd "${in_dir}" || exit $?
          fi
          unzip "${VERBOSE_FLAG[@]}" "$n"
        )
      ;;
      *.z|*.Z)                uncompress "$n"  ;;
      # ar is better for *.deb files
      *.deb)
        test "${VERBOSE}" -eq 0 && VERBOSE_FLAG=(v)

        # ar extracts "here", and debfiles have
        # multiple and similarly-named files
        if ! in_dir="$(in_temp "$n" "${FORCE_DIR}")" ; then
          echo "Failed to prepare '$n' for extraction!" >&2
        fi
        (cd "${in_dir}" && ar "${VERBOSE_FLAG[*]}"x "$n")
      ;;
      *.lz4)
        # We test quiet instead
        test "${VERBOSE}" -eq 1 && VERBOSE_FLAG=(q)

        lz4c -d"${VERBOSE_FLAG[*]}" "$n"
      ;;
      *.jar)
        test "${VERBOSE}" -eq 0 && VERBOSE_FLAG=(v)

        if ! in_dir="$(in_temp "$n" "${FORCE_DIR}")" ; then
          echo "Failed to prepare '$n' for extraction!" >&2
        fi
        (cd "${in_dir}" && jar "${VERBOSE_FLAG[*]}"xf "$n")
      ;;
      *.7z|*.arj|*.cab|*.cb7|*.chm|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar|*.apk)
                              7z x "$n"        ;;
      *.xz)                   unxz "$n"        ;;
      *.exe)                  cabextract "$n"  ;;
      *.cpio)
        test "${VERBOSE}" -eq 0 && VERBOSE_FLAG=(v)
        cpio -id"${VERBOSE_FLAG[*]}" < "$n"
      ;;
      *.cba|*.ace)            unace x "$n"     ;;
      *.zpaq)                 zpaq x "$n"      ;;
      *.arc)                  arc e "$n"       ;;
      *.cso)                  ciso 0 "$n" "$n.iso" && extract "$n.iso" && command rm -f "$n" ;;
      *)                      (exit "${status_unknown_archive}") ;;
      esac

      status="$?"
      # shellcheck disable=SC2181
      if [ "${status}" -ne 0 ] ; then
        case ${status} in
          "${status_unknown_archive}")
            msg='unknown archive method'
          ;;
          "${status_failure}")
            msg='extraction failed'
          ;;
          *) msg='unknown error!';;
        esac

        >&2 echo "${name}: '$n' - ${msg}; trying 7z"

        if ! (set -Eeuo pipefail ; 7z_cross_platform "$n" | sed 's/^/  /g') ; then
          EXIT_CODE="$((EXIT_CODE + 1))"
        fi
      fi

      if [ -n "${in_dir}" ] && [ "${in_dir}" != '.' ] ; then
        echo "Removing '${in_dir}/${n}' hardlink" >&2
        rm "${in_dir}/${n}" || echo "^^ FAILED!" >&2
      fi
  done

  # Avoid ${EXIT_CODE} going over the claimed limit
  if [ "${EXIT_CODE}" -gt 124 ] ; then
    >&2 echo "Error extracting ${EXIT_CODE} archives!!!"
    EXIT_CODE=124
  fi

  return "${EXIT_CODE}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  extract "$@"
fi
