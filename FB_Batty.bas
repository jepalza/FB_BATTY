#Include "fbgfx.bi"
#if __FB_LANG__ = "fb"
Using FB '' Scan code constants are stored in the FB namespace in lang FB
#endif

Randomize timer

' almacen de ladrillos para colisiones
Dim Shared As String colisiones(15,7) ' no uso el "0", por lo tanto son 15*7 empezando en el 1

Dim Shared anchopala As integer=3
Dim Shared As Integer mx,my,mb,ms ' el raton, solo uso el MX y el MB
Dim Shared As single bx,by,bxdir,bydir,velocidad ' la bola y su posicion y direccion (single, para moverse en decimas)
Dim Shared As Integer parado=TRUE ' empieza en posicion parado
mx=120:my=240
bx=mx+((anchopala*16)/2)-8
by=240-16
bxdir=1:bydir=-1
velocidad=5

Declare Sub juego()

' cadenas
Dim As String sa, sb, sc, sd, se, sf, sn

' enteros
Dim As Integer a, b, c, d, e, f, g, h, i, x, y, reg


Dim As Integer ancho, alto, colores, posicion, total, fila

' la pantalla REAL de una PDA es 240x320 (vertical de 320)
ancho=240
alto=320
' la pantalla del BATTY (la zona de juego) es de 240x240
' de los cuales, los bordes der. e izq. son 8+8 pixeles

posicion=0



' tres pantallas de 256 colores
' pantalla 0 visible
' pantalla 1 fondo
' pantalla 2 sprites
Screen 18,8,3

' cargo la pantalla BMP de graficos TAL CUAL, original, sobre la zona visible de mi pantalla
'BLoad "datos\graf.bmp" ' &h8790

Dim As Long dirinicioBMP=&h87b8 +1 ' +1 para compensar la forma de leer de FB
Dim As Integer pal=0
x=0:y=199
ScreenSet 2
Open "batty-arm.exe" For Binary As 1

	sc=Space(1024)
	Get #1,dirinicioBMP,sc
	For f=1 To Len(sc) Step 4
		Palette pal,RGB( Asc(Mid(sc,f+0,1))\4 , Asc(Mid(sc,f+1,1))\4 , Asc(Mid(sc,f+2,1))\4 )
		pal+=1
	Next
	
	dirinicioBMP+=Len(sc)
	
	sc=Space(256)
	While dirinicioBMP<&h185b8
		Get #1,dirinicioBMP,sc
		For f=1 To Len(sc)
			PSet(x,y),Asc(Mid(sc,f,1))
			x+=1:If x=320 Then x=0:y-=1
		Next
		dirinicioBMP+=Len(sc)		
	Wend
	
Close 1
ScreenCopy 2,0
'sleep



' dado que el color transparente en FB es el "0" para los modos de 8bits (como el que necesito)
' y en el BATTY original es el 15 (blanco), tengo que cambiar todos los 15 por 0
' y el que es "0" real, que deberia ser negro puro (reborde de sprites como paletas o pelotas) lo pongo como 255 
For f=0 To 319
	For g=64 To 199 ' NOTA: los ladrillos NO son transparentes, por lo que empiezo tras ellos (4*16 filas)
		If Point(f,g)=0  Then PSet (f,g),224 ' si es el 0, lo cambio por 255, negro
		If Point(f,g)=15 Then PSet (f,g),0   ' color 15=0, trasnparente para el FB
	Next
Next



' almacen de graficos
Dim Shared As Byte ladrillos(39,32*16*8)
Dim Shared As Byte especiales(19,32*16*8)
Dim Shared As Byte fondos(19,32*16*8)
Dim Shared As Byte normales(39,16*16*8)

' cinco anchos de palas 16,32,48,64,80, pero todas de 16 de alto (no uso la 0, es un lio, empieza en 1)
Dim Shared As Byte palas(1 To 6,1,16*16*8)

Dim Shared As Byte pantallas(20,420)

Dim Shared As Byte cuadro(ancho*alto*8)

' recojo los ladrillos
a=0:b=0
For f=0 To 3
	For g=0 To 9
		Get (g*32,f*16+b)-Step(31,15),ladrillos(a,0)
		Line(g*32,f*16+b)-Step(31,15),14,bf
		a+=1
	Next
Next


' graficos especiales
a=0:b=16*4 ' salto cuatro filas de 16 pixeles para llegar aqui
For f=0 To 1
	For g=0 To 9
		Get (g*32,f*16+b)-Step(31,15),especiales(a,0)
		a+=1
	Next
Next

' los bloques de fondos
a=0:b=(16*4)+(16*2) ' salto 4 + 2 filas de 16 pixel
For f=0 To 1
	For g=0 To 9
		Get (g*32,f*16+b)-Step(31,15),fondos(a,0)
		a+=1
	Next
Next

' y los normales
a=0:b=(16*4)+(16*2)+(16*2) ' salto 4+2+2 para llegar a los normales de 16x16
For f=0 To 1
	For g=0 To 19
		Get (g*16,f*16+b)-Step(15,15),normales(a,0)
		a+=1
	Next
Next

' palas
a=0:b=(16*4)+(16*2)+(16*2)+(16*2) ' salto 4+2+2+2 filas de pixels para llegar a las palas
' las palas son dos filas de 16 de alto, pero de 16,32,48,64,80 de ancho
'16
Get (0*16,0*16+b)-Step(15,15),palas(1,0,0)':Put (0, 0),palas16(0,0),PSet
Get (0*16,1*16+b)-Step(15,15),palas(1,1,0)':Put (0,16),palas16(1,0),PSet
'32
Get (1*16,0*16+b)-Step(31,15),palas(2,0,0)':Put (0, 0),palas32(0,0),PSet
Get (1*16,1*16+b)-Step(31,15),palas(2,1,0)':Put (0,16),palas32(1,0),PSet
'48
Get (3*16,0*16+b)-Step(47,15),palas(3,0,0)':Put (0, 0),palas48(0,0),PSet
Get (3*16,1*16+b)-Step(47,15),palas(3,1,0)':Put (0,16),palas48(1,0),PSet
'64
Get (6*16,0*16+b)-Step(63,15),palas(4,0,0)':Put (0, 0),palas64(0,0),PSet
Get (6*16,1*16+b)-Step(63,15),palas(4,1,0)':Put (0,16),palas64(1,0),PSet
'80
Get (10*16,0*16+b)-Step(79,15),palas(5,0,0)':Put (0, 0),palas80(0,0),PSet
Get (10*16,1*16+b)-Step(79,15),palas(5,1,0)':Put (0,16),palas80(1,0),PSet

' borro la pantalla temporal
ScreenSet 0:cls



' leemos las 20 pantallas desde el fichero original
' 20 pantallas de 420 (&h1A4) bytes cada una
' de los 420 bytes, son 7*15 (ancho,alto) de bloques de 4 bytes cada uno
' que hacen 7*15*4=420 bytes
' el primero es el numero de bloque, de 0 a 39 (los ladrillos son bloques de 32x16 pixel)
Dim As Integer inicio_pantallas
Open "datos\batty.exe" For Binary Access Read As 1
	inicio_pantallas=&h4B98 +1
	sc="    "' de 4 en 4 bytes, o sea, de bloque en bloque
	a=0
	b=0
	For f=inicio_pantallas To inicio_pantallas+(20*420) Step 4
		Get #1,f,sc
		c=Cvi(sc)
		pantallas(a,b)=c
		'Print sc,c,Cvi(sc),pantallas(a,b):sleep
		b+=1
		If b=420/4 Then b=0:a+=1
	Next
Close 1



' --------------- ponemos las pantallas -------------------
Dim Shared As Integer pantalla=0


' principal bucle
While 1
	' primero, el fondo en la pantalla 1
	ScreenSet 1
	a=pantalla
	If a>9 Then a=a-10 ' creo que solo hay 10 fondos, que se repiten 10+10 para las 20 pantallas
	b=a*2 ' el fondo son DOS sprites seguidos, uno encima del otro, para hacer 32x32
	For f=0 To 15 Step 2
		For g=0 To 8
			Put (g*32,(f+0)*16),fondos(b+0,0),pset
			Put (g*32,(f+1)*16),fondos(b+1,0),pset
		Next
	Next 
	' ahora, sobre este fondo, los bordes der. e izq. de 8+8 pixeles
	' en realidad, los sprites de bordes son de 16 de ancho, pero al dibujar en zona "no" visible
	' puedo hacerlo sin problema, y luego, mostrar solo los 8 necesarios
	For f=0 To 15
		Put (0,f*16),normales(38,0),PSet
		Put (240,f*16),normales(38,0),pset
	Next
	
	' aqui ponemos los ladrillos en la pantalla 2
	ScreenSet 2
	cls
	For f=1 To 15
		For g=1 To 7
			a=pantallas(pantalla,(f-1)*7+(g-1))
			a=(a And &h000000FF)
			If a>0 Then  ' ladrillo "0" no se dibuja, es vacio, hueco
				Put (g*32,f*16),ladrillos(a,0),PSet
				' y guardamos su posicion para las colisiones de una forma curiosa
				' en modo cadena texto separadas por una letra a,b,c para luego identificar su posicion
				' y guardo la esquina sup-izq y la inf-der
				colisiones(f,g)=Str(g*32)+"a"+str(f*16)+"b"+Str(g*32+32)+"c"+str(f*16+16)
			Else
				colisiones(f,g)="" ' vacio si no hay ladrillo
			EndIf
		Next
	Next 
	
	
	' -------------------------------------
	' aqui se desarrolla el juego
	' debe ser antes de ponerlo en pantalla
	' para poder estudiar colisiones sin el fondo
	' -------------------------------------
	  juego()
	' -------------------------------------
	
	
	' ahora, recupero la pantalla 2, la de sprites
	Get (32,16)-step(ancho-1,alto-1),cuadro(0)
	' me paso a la de fondo, la 1
	ScreenSet 1
	' y pongo los sprites en modo transparente sobre el fondo
	Put (16,16),cuadro(0),Trans
	' vuelvo a recoger el cuadro a mostrar, el de 240x240 una vez ya preparado
	Get (8,16)-step(ancho-1,ancho-1),cuadro(0)
	' por ultimo, muestro el resultado mezclado en la principal, la 0
	Cls
	ScreenSet 0
	Put (0,48),cuadro(0),pset
	
	If InKey=Chr(27) Then end

Wend

End




Sub juego()
	Dim col As Integer=0 ' control de colisiones
	Dim As Integer a,b
	
	' raton pala
	GetMouse mx,my,ms,mb
	If mx<32 Then mx=32
	If mx>256-(anchopala*16) Then mx=256-(anchopala*16)

	Put (mx,240),palas(anchopala,0,0),Trans 
	
	' bola rebotando
	If parado=TRUE Then 
		bydir=-1
		bx=mx+((anchopala*16)/2)-8
		If mb=1 Then 
			parado=FALSE
			by=by-1
			bxdir=Rnd(1)*IIf(Rnd(1)<0.5,-1,1)
		EndIf
	Else
		by=by+(bydir*velocidad)
		bx=bx+(bxdir*velocidad)
	EndIf


	If Rnd(1)<0.01 Then by=by-0.05:bx=bx-0.05 ' para evitar posibles bucles perdidos, osea, rombos ciclicos
		
	' limites en pantalla izq.der. arriba, abajo y en pala	
	If bx<32 Then bxdir*=-1:bx=32:col=9
	If bx>240 Then bxdir*=-1:bx=240:col=9
	If by<16 Then bydir*=-1:by=16:col=9
	If by>(240-15) Then 
		If (bx>(mx-16)) And (bx<(mx+(anchopala*16)+16)) Then
			bydir=-1
			by=240-17
			If bx<mx+16 Then bx=bx-2
			If Rnd(1)<0.05 Then by=by-1:bx=bx-1 ' para que rebote un poco mas aleatorio en la pala, y no sea siempre igual
		Else ' bola perdida, ha superado a la pala
		  If by>250 Then
			 	parado=TRUE
			 	by=240-16 ' posicion de origen "pegada" a la bola
			 	'no funciona Put (120-(anchopala*16),240),palas(anchopala,0,0),Trans 
			 	Exit Sub
		  EndIf
		EndIf
	EndIf


	
	' colisiones alrededor de la bola en 8 puntos
	If Point(bx+2.5,by+2.5)<>0 Then col=1
	If Point(bx+8,by+0)<>0 Then col=2
	If Point(bx+13.5,by+2.5)<>0 Then col=3
	If Point(bx+16,by+8)<>0 Then col=4
	If Point(bx+13.5,by+13.5)<>0 Then col=5
	If Point(bx+8,by+16)<>0 Then col=6
	If Point(bx+2.5,by+13.5)<>0 Then col=7
	If Point(bx+0,by+8)<>0 Then col=8
	
	If col=1 Then 
		bxdir*=-1
		bydir*=-1
		b= by+2.5
		a= bx+2.5
	EndIf
	If col=2 Then 
		bydir*=-1
		b= by
		a= bx+8
	EndIf
	If col=3 Then 
		bxdir*=-1
		bydir*=-1
		b= by+2.5
		a= bx+13.5
	EndIf
	If col=4 Then 
		bydir*=-1
		b= by+8
		a= bx+16
	EndIf
	If col=5 Then 
		bxdir*=-1
		bydir*=-1
		b= by+13.5
		a= bx+13.5
	EndIf
	If col=6 Then 
		bydir*=-1
		b= by+16
		a= bx+8
	EndIf
	If col=7 Then 
		bxdir*=-1
		bydir*=-1
		b= by+13.5
		a= bx+2.5
	EndIf
	If col=8 Then 
		bydir*=-1
		b= by+8
		a= bx
	EndIf

	If (col<>0) Then
	   'a=bx+16
	   'b=by
	   Dim As String s1
	   Dim As Integer a1,a2,b1,b2,ladrillos=0
		For f As Integer=1 To 15
			For g As Integer=1 To 7
				s1=colisiones(f,g)
				If s1<>"" Then ladrillos=1 ' para controlar cuando se acaban los ladrillos
				a1=Val(s1)
				b1=Val(Mid(s1,InStr(s1,"a")+1))
				a2=Val(Mid(s1,InStr(s1,"b")+1))
				b2=Val(Mid(s1,InStr(s1,"c")+1))
				If ((a>a1) And (a<a2) AndAlso (b>b1) And (b<b2)) Then 
					colisiones(f,g)=""
					pantallas(pantalla,(f-1)*7+(g-1))=0
				EndIf
			Next
		Next
		If ladrillos=0 Then 
			pantalla+=1 ' fin de esta pantalla, pasamos a la siguiente
			parado=TRUE
			by=240-16 ' posicion de origen "pegada" a la bola
			'no funciona Put (120-(anchopala*16),240),palas(anchopala,0,0),Trans 
			Exit Sub
		EndIf
	EndIf

	' para ver como desaparecen los ladrillos
	'ScreenSet 0
	'For f As Integer=1 To 15
	'	For g As Integer=1 To 7
	'		Locate f,g+40
	'		Print IIf(colisiones(f,g)<>"","1","0")
	'	Next
	'Next
	'a= (by/16)-1
	'b= ((bx+32)/32)-1
	'Locate a,b+40
	'Print "*"
	'Sleep 10
	'ScreenSet 2



	' la bola es el grafico 0
	Put (bx,by),normales(0,0),Trans 	

		
	Sleep 1
End Sub
