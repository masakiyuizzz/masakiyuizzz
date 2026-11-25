import re, sys, time

VER = str(int(time.time()))
PAT = re.compile(r'(https://raw\.githubusercontent\.com/masakiyuizzz/masakiyuizzz/main/[^"\s]+?\.png)(\?v=\d+)?')

for f in ['README.md', 'README.en.md']:
    s = open(f, encoding='utf-8').read()
    n = len(PAT.findall(s))
    s = PAT.sub(lambda m: m.group(1) + '?v=' + VER, s)
    open(f, 'w', encoding='utf-8').write(s)
    print('  %s  %d urls -> v=%s' % (f, n, VER))
