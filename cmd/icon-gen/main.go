// Command icon-gen builds the Windows tray .ico and Chrome extension PNG icons.
// It uses only Go's standard library so release builds need no image tooling.
package main

import (
    "bytes"
    "encoding/binary"
    "image"
    "image/color"
    "image/png"
    "math"
    "os"
    "path/filepath"
)

type rgba struct{ r, g, b, a float64 }
func paint(r,g,b uint8) rgba { return rgba{float64(r),float64(g),float64(b),255} }
func dist(x,y,ax,ay,bx,by float64) float64 {
    dx,dy:=bx-ax,by-ay
    t:=0.0
    if denom:=dx*dx+dy*dy;denom>0 { t=math.Max(0,math.Min(1,((x-ax)*dx+(y-ay)*dy)/denom)) }
    return math.Hypot(x-(ax+t*dx),y-(ay+t*dy))
}
func rounded(x,y float64) bool {
    qx:=math.Max(math.Abs(x-128)-76,0)
    qy:=math.Max(math.Abs(y-128)-76,0)
    return math.Hypot(qx,qy)<=52
}
func sample(x,y float64) rgba {
    c:=rgba{}
    if !rounded(x,y) {return c}
    c=paint(11,11,13)
    if math.Abs(math.Hypot(x-128,y-128)-78)<4 {c=paint(111,89,58)}
    if math.Abs(math.Hypot(x-128,y-128)-54)<11 {c=paint(23,23,27)}
    if math.Abs(math.Abs(x-128)+math.Abs(y-128)-48)<5.5 {c=paint(201,164,106)}
    if math.Hypot(x-207,y-128)<10 {c=paint(224,193,142)}
    if dist(x,y,128,83,128,153)<4.8 ||
       dist(x,y,128,153,155,126)<4.8 ||
       dist(x,y,128,153,101,126)<4.8 {
        c=paint(242,239,232)
    }
    if dist(x,y,89,180,167,180)<4 {c=paint(143,140,145)}
    return c
}
func render(size int) *image.NRGBA {
    out:=image.NewNRGBA(image.Rect(0,0,size,size))
    const n=4
    for y:=0;y<size;y++ {for x:=0;x<size;x++ {
        var r,g,b,a float64
        for sy:=0;sy<n;sy++ {for sx:=0;sx<n;sx++ {
            c:=sample((float64(x)+(float64(sx)+.5)/n)*256/float64(size),
                      (float64(y)+(float64(sy)+.5)/n)*256/float64(size))
            r+=c.r*c.a/255;g+=c.g*c.a/255;b+=c.b*c.a/255;a+=c.a
        }}
        scale:=1/float64(n*n)
        a*=scale;r*=scale;g*=scale;b*=scale
        if a>0 {r=r*255/a;g=g*255/a;b=b*255/a}
        out.SetNRGBA(x,y,color.NRGBA{uint8(r+.5),uint8(g+.5),uint8(b+.5),uint8(a+.5)})
    }}
    return out
}
func pngBytes(size int) ([]byte,error) {
    var buf bytes.Buffer
    if err:=png.Encode(&buf,render(size));err!=nil{return nil,err}
    return buf.Bytes(),nil
}
func writeICO(path string,sizes []int) error {
    frames:=make([][]byte,len(sizes))
    for i,size:=range sizes {data,err:=pngBytes(size);if err!=nil{return err};frames[i]=data}
    var buf bytes.Buffer
    binary.Write(&buf,binary.LittleEndian,uint16(0))
    binary.Write(&buf,binary.LittleEndian,uint16(1))
    binary.Write(&buf,binary.LittleEndian,uint16(len(sizes)))
    offset:=6+16*len(sizes)
    for i,size:=range sizes {
        width:=byte(size);height:=byte(size) // 256 is represented as 0
        buf.Write([]byte{width,height,0,0})
        binary.Write(&buf,binary.LittleEndian,uint16(1))
        binary.Write(&buf,binary.LittleEndian,uint16(32))
        binary.Write(&buf,binary.LittleEndian,uint32(len(frames[i])))
        binary.Write(&buf,binary.LittleEndian,uint32(offset))
        offset+=len(frames[i])
    }
    for _,frame:=range frames {buf.Write(frame)}
    return os.WriteFile(path,buf.Bytes(),0644)
}
func main() {
    if err:=os.MkdirAll("extension/icons",0755);err!=nil{panic(err)}
    for _,size:=range []int{16,32,48,128} {
        data,err:=pngBytes(size);if err!=nil{panic(err)}
        path:=filepath.Join("extension","icons", "icon"+itoa(size)+".png")
        if err:=os.WriteFile(path,data,0644);err!=nil{panic(err)}
    }
    if err:=writeICO("BoltDM.ico",[]int{16,32,48,256});err!=nil{panic(err)}
}
func itoa(n int) string {
    if n==0{return "0"}
    var b [20]byte
    i:=len(b)
    for n>0 {i--;b[i]=byte(n%10)+'0';n/=10}
    return string(b[i:])
}
