gscombine() {
  # Show usage
  if [ "$#" -lt 1 ]; then
    echo "Usage: gscombine [-o output.pdf] file1.pdf [file2.pdf ...]"
    echo "If no -o/--output flag is given, output will be combined.pdf"
    return 1
  fi

  local output="combined.pdf"
  local files=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        if [ -n "$2" ]; then
          output="$2"
          shift 2
        else
          echo "Error: Missing filename after $1"
          return 1
        fi
        ;;
      *)
        files+=("$1")
        shift
        ;;
    esac
  done

  if [ "${#files[@]}" -lt 2 ]; then
    echo "Error: Need at least two input PDFs to combine."
    return 1
  fi

  echo "🔧 Combining ${#files[@]} file(s) → $output"

  gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dAutoRotatePages=/None -sOutputFile="$output" "${files[@]}"

  if [ $? -eq 0 ]; then
    echo "✅ Created $output"
  else
    echo "❌ Ghostscript failed"
  fi
}


gscompress() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: gscompress file1.pdf [file2.pdf ...]"
    return 1
  fi

  for infile in "$@"; do
    if [[ "$infile" != *.pdf ]]; then
      echo "Skipping '$infile' (not a PDF)"
      continue
    fi

    # Remove .pdf extension and create output name
    local base="${infile%.pdf}"
    local outfile="${base}_compressed.pdf"

    echo "🔧 Compressing $infile → $outfile"

    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/ebook \
       -dNOPAUSE -dQUIET -dBATCH \
       -sOutputFile="$outfile" \
       "$infile"

    if [ $? -eq 0 ]; then
      echo "✅ Created $outfile"
    else
      echo "❌ Failed to compress $infile"
    fi
  done
}
SETUP_BASE_DIR=$(cd "$(dirname -- "${BASH_SOURCE[0]}")/../.."; pwd)
export RIPGREP_CONFIG_PATH=${GIT_SETUP_DIR}/configs/ripgreprc
