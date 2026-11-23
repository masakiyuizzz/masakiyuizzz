#!/bin/zsh
# 重新导出 README 用的卡片图。改完 index.html 里的数字后跑一下这个。
set -e
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

measure() {
  "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-software-rasterizer \
    --hide-scrollbars --window-size=880,1600 --virtual-time-budget=1500 --dump-dom \
    "file://$ROOT/index.html?shot=$1&theme=$2&open=none&expand=all" 2>/dev/null \
    | grep -o "<title>[0-9]*</title>" | head -1 | grep -o "[0-9]*"
}

shot() {
  "$CHROME" --headless=new --no-sandbox --disable-gpu --disable-software-rasterizer \
    --hide-scrollbars --force-device-scale-factor=2 --default-background-color=00000000 \
    --window-size=880,$3 --screenshot="$2" \
    "file://$ROOT/index.html?shot=$1&theme=$4&open=none&expand=${5:-none}" >/dev/null 2>&1
}

for th in dark light; do
  for t in org about prog; do
    H=$(measure $t $th)
    if [ "$t" = "prog" ]; then
      shot $t "profile/card-$t-$th.png" $((H + 16)) $th all
    else
      shot $t "profile/card-$t-$th.png" $((H + 16)) $th
    fi
    echo "  card-$t-$th.png  ${H}px"
  done
  H=$(measure hero $th)
  shot hero "profile/card-hero-$th.png" $H $th
  echo "  card-hero-$th.png  ${H}px"
done

for th in dark light; do
  H=$(measure dock $th)
  shot dock "profile/card-dock-$th.png" $((H + 12)) $th
  echo "  card-dock-$th.png  ${H}px"
done

python3 tools/trim.py profile/card-org-*.png profile/card-about-*.png \
  profile/card-prog-*.png profile/card-dock-*.png
echo "导出完成"
