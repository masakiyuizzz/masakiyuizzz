import zlib,struct,sys

def read_png(path):
    d=open(path,'rb').read(); i=8; idat=b''
    w=h=bd=ct=0
    while i<len(d):
        ln=struct.unpack('>I',d[i:i+4])[0]; typ=d[i+4:i+8]; data=d[i+8:i+8+ln]; i+=12+ln
        if typ==b'IHDR': w,h,bd,ct=struct.unpack('>IIBB',data[:10])
        elif typ==b'IDAT': idat+=data
        elif typ==b'IEND': break
    raw=zlib.decompress(idat); ch={0:1,2:3,4:2,6:4}[ct]; stride=w*ch
    out=bytearray(); prev=bytearray(stride); pos=0
    for y in range(h):
        f=raw[pos]; pos+=1
        line=bytearray(raw[pos:pos+stride]); pos+=stride
        for x in range(stride):
            a=line[x-ch] if x>=ch else 0; b=prev[x]; c=prev[x-ch] if x>=ch else 0
            if f==1: line[x]=(line[x]+a)&255
            elif f==2: line[x]=(line[x]+b)&255
            elif f==3: line[x]=(line[x]+(a+b)//2)&255
            elif f==4:
                pp=a+b-c; pa=abs(pp-a); pb=abs(pp-b); pc=abs(pp-c)
                pr=a if(pa<=pb and pa<=pc) else (b if pb<=pc else c)
                line[x]=(line[x]+pr)&255
        out+=line; prev=line
    return w,h,ch,out

def write_png(path,w,h,ch,buf):
    ct={1:0,2:4,3:2,4:6}[ch]
    raw=bytearray()
    for y in range(h):
        raw.append(0); raw+=buf[y*w*ch:(y+1)*w*ch]
    def chunk(t,data):
        return struct.pack('>I',len(data))+t+data+struct.pack('>I',zlib.crc32(t+data)&0xffffffff)
    png=b'\x89PNG\r\n\x1a\n'
    png+=chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,ct,0,0,0))
    png+=chunk(b'IDAT',zlib.compress(bytes(raw),9))
    png+=chunk(b'IEND',b'')
    open(path,'wb').write(png)

def trim(src,dst):
    w,h,ch,buf=read_png(src)
    if ch!=4: return False
    minx,miny,maxx,maxy=w,h,-1,-1
    for y in range(h):
        row=buf[y*w*ch:(y+1)*w*ch]
        for x in range(0,w):
            if row[x*ch+3]>8:
                if x<minx:minx=x
                if x>maxx:maxx=x
                if y<miny:miny=y
                maxy=y
    if maxx<0: return False
    nw,nh=maxx-minx+1,maxy-miny+1
    out=bytearray()
    for y in range(miny,maxy+1):
        out+=buf[(y*w+minx)*ch:(y*w+maxx+1)*ch]
    write_png(dst,nw,nh,ch,out)
    print('trim',src.split('/')[-1],w,h,'->',nw,nh)
    return True

for p in sys.argv[1:]:
    trim(p,p)
