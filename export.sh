#!/bin/zsh
# 重新导出 README 用的所有图。改完 index.html 里的数字后跑一下这个。
set -e
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

measure() {
  "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-software-rasterizer \
    --hide-scrollbars --window-size=880,1600 --virtual-time-budget=1500 --dump-dom \
    "file://$ROOT/index.html?shot=$1&theme=$2&lang=$3&open=none&expand=all" 2>/dev/null \
    | grep -o "<title>[0-9]*</title>" | head -1 | grep -o "[0-9]*"
}

shot() {
  "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-software-rasterizer \
    --hide-scrollbars --force-device-scale-factor=2 --default-background-color=00000000 \
    --window-size=$3,$4 --screenshot="$2" \
    "file://$ROOT/index.html?shot=$5&theme=$6&lang=$7&open=none&expand=all" >/dev/null 2>&1
}

for lang in zh en; do
  for th in dark light; do
    for t in hero org about prog; do
      H=$(measure $t $th $lang)
      shot $t "profile/$t-$lang-$th.png" 880 $((H + 16)) $t $th $lang
      echo "  $t-$lang-$th.png  ${H}px"
    done
  done
done

for th in dark light; do
  shot ts "profile/ts-$th.png" 400 60 ts $th zh
  echo "  ts-$th.png"
  for lg in zh en; do
    shot lang "profile/lang-$lg-$th.png" 400 60 lang $th $lg
    echo "  lang-$lg-$th.png"
  done
done

python3 tools/trim.py profile/*.png
echo "导出完成"
