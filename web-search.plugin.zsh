# Web search from the terminal
# Functions borrowed and adapted from Oh My Zsh
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/functions.zsh

# URL-encodes a string using RFC 2396.
function omz_urlencode() {
  emulate -L zsh
  local -a opts
  zparseopts -D -E -a opts r m P

  local in_str="$@"
  local url_str=""
  local spaces_as_plus=1
  [[ -n $opts[(r)-P] ]] && spaces_as_plus=""
  local str="$in_str"

  # Fallback to UTF-8 if CODESET is not defined to prevent iconv errors.
  local encoding=${langinfo[CODESET]:-UTF-8}

  # Convert string to UTF-8 if necessary.
  local -a safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
    str=$(echo -E "$str" | iconv -f "$encoding" -t UTF-8 2>/dev/null)
    if [[ $? != 0 ]]; then
      echo "Error: Could not convert string from '$encoding' to 'UTF-8'." >&2
      return 1
    fi
  fi

  # Use LC_ALL=C to process text byte-by-byte.
  local i byte ord LC_ALL=C
  export LC_ALL
  local reserved=';/?:@&=+$,'
  local mark='_.!~*''()-'
  local dont_escape="[A-Za-z0-9"
  [[ -z $opts[(r)-r] ]] && dont_escape+=$reserved
  [[ -z $opts[(r)-m] ]] && dont_escape+=$mark
  dont_escape+="]"

  for (( i = 1; i <= ${#str}; ++i )); do
    byte="$str[i]"
    if [[ "$byte" =~ "$dont_escape" ]]; then
      url_str+="$byte"
    elif [[ "$byte" == " " && -n "$spaces_as_plus" ]]; then
      url_str+="+"
    else
      ord=$(printf "%02X" "'$byte")
      url_str+="%$ord"
    fi
  done
  echo -E "$url_str"
}

# Opens a file or URL with the default application.
function open_command() {
  local open_cmd

  # Define the open command based on the OS.
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='xdg-open' || open_cmd='cmd.exe /c start ""' ;;
    msys*)    open_cmd='start ""' ;;
    *)
      echo "Error: Platform '$OSTYPE' not supported." >&2
      return 1
      ;;
  esac

  # Handle WSL path conversion for files.
  if [[ "$OSTYPE" = linux* && "$(uname -r)" = *icrosoft* && -e "$1" ]]; then
      1="$(wslpath -w "${1:a}")" || return 1
  fi

  # Use $BROWSER if it's set for URLs.
  if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]; then
    "$BROWSER" "$@" &>/dev/null &! # Run in background and disown
    echo "✅ Done!"
    return
  fi

  # Run the default command, disowning it to suppress job messages
  ${=open_cmd} "$@" &>/dev/null &!
  echo "✅ Done!"
}

# Performs a web search using a specified engine.
function web() {
  emulate -L zsh

  # Define search engine URLs.
  typeset -A urls
  urls=(
    $ZSH_WEB_SEARCH_ENGINES
    google        "https://www.google.com/search?q="
    bing          "https://www.bing.com/search?q="
    brave         "https://search.brave.com/search?q="
    yahoo         "https://search.yahoo.com/search?p="
    duckduckgo    "https://www.duckduckgo.com/?q="
    startpage     "https://www.startpage.com/do/search?q="
    yandex        "https://yandex.ru/yandsearch?text="
    github        "https://github.com/search?q="
    baidu         "https://www.baidu.com/s?wd="
    ecosia        "https://www.ecosia.org/search?q="
    goodreads     "https://www.goodreads.com/search?q="
    qwant         "https://www.qwant.com/?q="
    givero        "https://www.givero.com/search?q="
    stackoverflow "https://stackoverflow.com/search?q="
    wolframalpha  "https://www.wolframalpha.com/input/?i="
    archive       "https://web.archive.org/web/*/"
    scholar       "https://scholar.google.com/scholar?q="
    ask           "https://www.ask.com/web?q="
    youtube       "https://www.youtube.com/results?search_query="
    grok          "https://grok.com/c?q="
    google-ai     "https://www.google.com/search?udm=50&source=searchlabs&q=yourquery"
    twitter       "https://x.com/search?q="
    chatgpt       "https://chatgpt/?q="
    mistral       "https://chat.mistral.ai/chat/q="
  )

  # Handle flags
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: web <engine> [query]"
    echo "       web [-l | --list] [-h | --help]"
    echo "\nFlags:"
    echo "  -l, --list    List all available search engines."
    echo "  -h, --help    Show this help message."
    return 0
  fi

  if [[ "$1" == "-l" || "$1" == "--list" || $# -eq 0 ]]; then
    echo "Available search engines:"
    print -l ${(ko)urls} # Print sorted keys of the urls array
    return 0
  fi

  # Check if the search engine is supported.
  if [[ -z "$urls[$1]" ]]; then
    echo "Search engine '$1' not supported."
    return 1
  fi

  local url
  # Search or go to the main page depending on the number of arguments.
  if [[ $# -gt 1 ]]; then
    # Build search URL.
    url="${urls[$1]}$(omz_urlencode -r ${@[2,-1]})"
  else
    # Build main page URL.
    url="${(j://:)${(s:/:)urls[$1]}[1,2]}"
  fi

  open_command "$url"
}

# --- ALIASES ---
alias bing='web bing'
alias brs='web brave'
alias google='web google'
alias g='web google'
alias yahoo='web yahoo'
alias ddg='web duckduckgo'
alias sp='web startpage'
alias yandex='web yandex'
alias github='web github'
alias baidu='web baidu'
alias ecosia='web ecosia'
alias goodreads='web goodreads'
alias qwant='web qwant'
alias givero='web givero'
alias stackoverflow='web stackoverflow'
alias wolframalpha='web wolframalpha'
alias archive='web archive'
alias scholar='web scholar'
alias ask='web ask'
alias youtube='web youtube'
alias yt='web youtube'

# --- Custom AI/Social Aliases ---
alias grok='web grok'
alias grk='web grok'
alias twitter='web twitter'
alias tw='web twitter'
alias google-ai='web google-ai'
alias gai='web google-ai'
alias chatgpt='web chatgpt'
alias mistral='web mistral'
alias mist='web mistral'

# Add aliases for custom search engines
if [[ ${#ZSH_WEB_SEARCH_ENGINES} -gt 0 ]]; then
  typeset -A engines
  engines=($ZSH_WEB_SEARCH_ENGINES)
  for key in ${(k)engines}; do
    alias "$key"="web $key"
  done
  unset engines key
fi
