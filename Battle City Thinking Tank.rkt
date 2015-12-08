#lang racket
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;universe: Libreria para la creacion de mundos interactivos
;image: Libreria para el manejo de imagenes
;posn: Estructura para el manejo de posiciones de imagenes
(require 2htdp/universe 2htdp/image  2htdp/batch-io lang/posn)
;;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;; Autor: Aurelio Vivas 
;; Fecha: 12/03/2015
;; Nombre: Battle City Thinking Tank
;; Vesion: 7 
;;::::::::::::::::::::::::::: GRAFICOS DEL MUNDO ::::::::::::::::::::::::::::
; Imagenes del tanque del jugador
(define JUG_ARRIBA (bitmap "imagenes/jug_arriba.png"))
(define JUG_ABAJO(bitmap "imagenes/jug_abajo.png"))
(define JUG_IZQUIERDA (bitmap "imagenes/jug_izquierda.png"))
(define JUG_DERECHA (bitmap "imagenes/jug_derecha.png"))

; Imagenes del tanque enemigo
(define ENE_ARRIBA (bitmap "imagenes/ene_arriba.png"))
(define ENE_ABAJO (bitmap "imagenes/ene_abajo.png"))
(define ENE_IZQUIERDA (bitmap "imagenes/ene_izquierda.png"))
(define ENE_DERECHA (bitmap "imagenes/ene_derecha.png"))

; Imagen de la base del jugador 
(define BASE (bitmap "imagenes/jug_base.png"))

; Imagen de una bala 
(define BALA (circle 5 'solid 'black))

; Imagen ladrillo
(define LADRILLO (bitmap "imagenes/ladrillo1.png"))

; Imagen de la arena del juego 
(define AREA_JUEGO 
  (place-image (line 0 600 "black") 700 300 (empty-scene 800 600)))

; Dimensiones de la pantalla del juego 
(define ANCHO 700)
(define ALTO 600)


;;::::::::::::::::::::::::: DEFINICION DE TIPOS DE DATOS :::::::::::::::::::
;Mundo:
;jugador (tanque): Estructura que representa el tanque del jugador
;base (base): Estructura tipo base que representara la base del jugador
;balas (bala): Lista de estructuras tipo bala que representaran las balas disparadas por los tanques
;ladrillos (ladrillo): Lista de estructuras tipo ladrillo
;enemigos (list-of-tanque): Lista de estructuras tipo tanque que representaran los tanques enemigos 
;preguntas (list-of-pregunta): Lista de estructuras tipo pregunta 
;pregunta (pregunta): estructura de tipo pregunta
(struct mundo (jugador base balas ladrillos enemigos preguntas pregunta) #:transparent)

;Imagen Tanque
;arriba (bitmap): Imagen que representa el tanque con direccion hacia arriba
;abajo (bitmap): Imagen que representa el tanque con direccion hacia abajo
;izquierda (bitmap): Imagen que representa el tanque con direccion hacia la izquierda
;derecha (bitmap): Imagen que representa el tanque con direccion hacia la derecha
(struct imagen_tanque (arriba abajo izquierda derecha))

;Tanque
;tipo: (string): Permite saber si el tanque es jugador o enemigo
;imagen (imagen): Estructura que representa el tanque en diferentes direcciones
;posn (posn): Estructura que indica en que punto de la pantalla del juego se dibujara el tanque
;direccion (string): string que indicara en que direccion se esta moveindo el tanque ("up", "down", "left", "right")
;velocidad (number): numero que indica cuantos pixeles se movera el tanque debido al evento del teclado en el caso
;del jugador. en el caso de los tanques enemigos con el evento del tick del reloj del sistema
;vidas (number): Representa el numero de vidas que tiene el tanque
(struct tanque (tipo imagen posn direccion velocidad vidas))

;Bala
;posn (posn): Estructura que define el punto donde empieza la trayectoria de la bala 
;direccion (string): Describe la direccion de la bala ("up", "down", "left", "right")
;destino (string): indica si la bala va dirigida (de un jugador a un enemigo) o (de un enemigo a un jugador)
(struct bala (posn direccion destino))

;Ladrillo
;posn (posn): Estructura que define la posicion de un ladrillo en la pantalla
(struct ladrillo (posn))

;Base
;posn (posn): Estructura que define la posicion de la base en la pantalla del juego
;vidas (number): numero de vidas que tiene la base del jugador
(struct base (posn vidas))

;Pregunta:
;enunciado (string): indica el enunciado de la pregunta
;opciones (string): indica las opciones de respuesta
;respuesta (estring): indica la respuesta correcta a la pregunta 
(struct pregunta (enunciado opciones respuesta) #:transparent)

;Indicador
;imagen (imagen): Imagen quer permite visualizar el estado del juego
;posn (posn): Estructura que indica la posicion del indicador en la pantalla del juego
(struct indicador (imagen posn))

;;::::::::::::::::::::::::: CONSTANTES ::::::::::::::::::::::::::::::

;Identifican las posibilidades de movimiento del jugador o del enemigo
(define ARRIBA "up")
(define ABAJO "down")
(define IZQUIERDA "left")
(define DERECHA "right")

;indica cuantos pixeles los objetos
(define VELOCIDAD_JUGADOR 8)
(define VELOCIDAD_ENEMIGO 4)
(define VELOCIDAD_BALA 8)

;Indican las vidas de el jugador, cada enemigo y la base
(define VIDAS_JUGADOR 2)
(define VIDAS_ENEMIGO 2)
(define VIDAS_BASE 2)

;Identifican el tipo de tanque
(define TIPO_JUGADOR "jugador")
(define TIPO_ENEMIGO "enemigo")

;Variantes definidas para el movimieno de los enemigos y balas
(define RANGO_MOVIMIENTO 20)
(define RANGO_DISPARO 40)
(define DISTANCIA 10)
(define VELOCIDAD_TICK 1/28)
(define MOVIMIENTOS_ENEMIGO (list ARRIBA ABAJO IZQUIERDA DERECHA))

;Imagen y estructura jugador 
(define IMAGEN_JUGADOR (imagen_tanque JUG_ARRIBA JUG_ABAJO JUG_IZQUIERDA JUG_DERECHA))
(define JUGADOR (tanque TIPO_JUGADOR IMAGEN_JUGADOR (make-posn 550 550) ARRIBA VELOCIDAD_JUGADOR VIDAS_JUGADOR))

;Imagen y estructuras de los enemigos
(define IMAGEN_ENEMIGO (imagen_tanque ENE_ARRIBA ENE_ABAJO ENE_IZQUIERDA ENE_DERECHA))
(define ENEMIGOS (list (tanque TIPO_ENEMIGO IMAGEN_ENEMIGO (make-posn 80 50) ABAJO VELOCIDAD_ENEMIGO VIDAS_ENEMIGO)
                       (tanque TIPO_ENEMIGO IMAGEN_ENEMIGO (make-posn 160 50) ABAJO VELOCIDAD_ENEMIGO VIDAS_ENEMIGO)
                       (tanque TIPO_ENEMIGO IMAGEN_ENEMIGO (make-posn 210 50) ABAJO VELOCIDAD_ENEMIGO VIDAS_ENEMIGO)
                       (tanque TIPO_ENEMIGO IMAGEN_ENEMIGO (make-posn 290 50) ABAJO VELOCIDAD_ENEMIGO VIDAS_ENEMIGO)))

;Base del jugador y lista de ladrillos que la protegen
(define BASE_JUGADOR (base (make-posn 345 575) VIDAS_BASE))
(define PROTECCION_BASE (list (ladrillo (make-posn 300 575))
                              (ladrillo (make-posn 300 525))
                              (ladrillo (make-posn 350 525))
                              (ladrillo (make-posn 400 525))
                              (ladrillo (make-posn 400 575))))




;Balas
(define BALAS empty)


;Ladrillos 
;generadorLadrillos: number * number -> list-of-ladrillos
;permite generar una lista de ladrillos en posiciones consecutivas
(define (generadorLadrillos x y)
  (cond
    [(and (>= x 650) (>= y 450)) (cons (ladrillo (make-posn x y)) empty)]
    [(>= x 650) (cons (ladrillo (make-posn x y)) (generadorLadrillos 25 (+ y 50)))]
    [else (cons (ladrillo (make-posn x y)) (generadorLadrillos (+ x 50) y))]))

(define LADRILLOS (append (generadorLadrillos 25 100) PROTECCION_BASE))


;Banco preguntas
;cargarPreguntas: string -> list-of-pregunta
;permite cargar de un archivo las preguntas del juego
(define (cargarPreguntas archivo)
  (define lista_lineas (read-lines archivo))
  (let loop ((preguntas lista_lineas))
    (if (empty? preguntas)
        empty
        (cons 
         (pregunta 
          (list-ref preguntas 0)
          (string-append (list-ref preguntas 1)
                         " "
                         (list-ref preguntas 2)
                         " "
                         (list-ref preguntas 3)
                         " "
                         (list-ref preguntas 4))
          (list-ref preguntas 5))
         (loop (rest (rest (rest (rest (rest (rest preguntas)))))))))))

(define PREGUNTAS (cargarPreguntas "Banco Preguntas.txt"))
(define PREGUNTA_VACIA null)
(define POSN_ENUNCIADO_PREGUNTA (make-posn 350 350))
(define POSN_OPCIONES_PREGUNTA (make-posn 350 400))


;Primer estado del mundo
(define MUNDO_INICIAL (mundo JUGADOR BASE_JUGADOR BALAS LADRILLOS ENEMIGOS PREGUNTAS PREGUNTA_VACIA))

;;:::::::::::::::::::::::::::: PINTAR JUEGO ::::::::::::::::::::::::::::::::
;imagenTanque: tanque -> imagen
;determina que imagen se debe colocar, teniendo en cuenta la direccion a la que se dirige el tanque
;tanque: representa el tanque a pintar en el mundo
(define (imagenTanque tanque)
  (cond
    [(equal? (tanque-direccion tanque) ARRIBA) (imagen_tanque-arriba (tanque-imagen tanque))]
    [(equal? (tanque-direccion tanque) ABAJO) (imagen_tanque-abajo (tanque-imagen tanque))]
    [(equal? (tanque-direccion tanque) IZQUIERDA) (imagen_tanque-izquierda (tanque-imagen tanque))]
    [(equal? (tanque-direccion tanque) DERECHA) (imagen_tanque-derecha (tanque-imagen tanque))]))


;listaImagenes: (list-of tanque + bala + ladrillo + indicador) -> list-of-imagen
;permite obtener las imagenes de una lista de objetos 
(define (listaImagenes objetos)
  (cond
    [(empty? objetos) empty]
    [else (cons (objeto->imagen (first objetos)) (listaImagenes (rest objetos)))]))

;listaPosiciones: (list-of tanque + bala + ladrillo + indicador) -> list-of-posn
;permite obtener una lista de las posiciones de los objetos
(define (listaPosiciones objetos)
  (cond
    [(empty? objetos) empty]
    [else (append (list (objeto->posn (first objetos))) (listaPosiciones (rest objetos)))]))

;imagenIndicador: mundo -> imagen
;permite extraer y mostrar los detalles mas importantes del mundo
(define (imagenIndicador mundo)
  (define jugador (mundo-jugador mundo))
  (define posn_jugador (tanque-posn jugador))
  (define vidas_jugador (tanque-vidas jugador))
  (define vidas_base (base-vidas (mundo-base mundo)))
  (define num_enemigos (length (mundo-enemigos mundo)))
  (place-images/align
   (list (text (string-append "Posicion: " (number->string (posn-x posn_jugador)) "," (number->string (posn-y posn_jugador))) 10 "yellowgreen")
         (text (string-append "Jugador: " (number->string vidas_jugador)) 10 "yellowgreen") 
         (text (string-append "Base: " (number->string vidas_base)) 10 "yellowgreen")
         (text (string-append "No.Enemigos: " (number->string num_enemigos)) 10 "yellowgreen")
         (text (if (or (= 0 vidas_jugador) (= 0 vidas_base)) "¡¡GAME OVER!!" " ") 10 "yellowgreen")
         (text (if (= 0 num_enemigos) "¡¡HAS GANADO!!" " ") 10 "yellowgreen"))
   (list (make-posn 90 16) (make-posn 90 32) (make-posn 90 48) (make-posn 90 64) (make-posn 90 80) (make-posn 90 100))
   "right" "bottom" (empty-scene 100 600)))

;pintarJuego: mundo -> imagen
;permite obtener una imagen donde estan el jugador, enemigos, ladrillos y
;el indicador del estado del mundo.
(define (pintarJuego mundo)
  (define jugador (mundo-jugador mundo))
  (define base_jugador (mundo-base mundo))
  (define balas (mundo-balas mundo))
  (define ladrillos (mundo-ladrillos mundo))
  (define enemigos (mundo-enemigos mundo))
  (define estadoJuego (indicador (imagenIndicador mundo) (make-posn 750 300)))
  (define objetos (append (list estadoJuego) (list jugador) (list base_jugador) balas ladrillos enemigos))
  (define imagenes (listaImagenes objetos))
  (define posiciones (listaPosiciones objetos))
  (place-images imagenes posiciones AREA_JUEGO))

;pintarPregunta: mundo -> imagen
;permite obtener una imagen donde se encuentra una pregunta y 
;el inidcador del estado del juego
(define (pintarPregunta mundo)
  (define pregunta (mundo-pregunta mundo))
  (define enunciado (pregunta-enunciado pregunta))
  (define opciones (pregunta-opciones pregunta))
  (place-images/align
   (list (text enunciado 20 "yellowgreen")
         (text opciones 20 "yellowgreen")
         (imagenIndicador mundo))
   (list POSN_ENUNCIADO_PREGUNTA
         POSN_OPCIONES_PREGUNTA
         (make-posn 750 300))
   "center" "center"
   (empty-scene 800 600)))


;pintarMundo: mundo -> imagen
;si en el atributo "pregunta" del mundo hay una pregunta, entonces
;retorna una imagen con la pregunta y el estado del juego.
;de lo contrario entonces retorna una imagen con el jugados, enemigos,
;ladrillos, base y el estado del juego
(define (pintarMundo mundo)
  (if (pregunta? (mundo-pregunta mundo))
      (pintarPregunta mundo)
      (pintarJuego mundo)))


;;:::::::::::::::::::::::::::: FUNCIONES :::::::::::::::::::::::::::::::: 

;; EXTRACTORAS
;objeto->imagen: (tanque | bala | ladrillo | indicador) -> imagen
;permite obtener la imagen de algun tipo de estructura (tanque, bala, ladrillo)
(define (objeto->imagen objeto)
  (cond
    [(tanque? objeto) (imagenTanque objeto)]
    [(bala? objeto) BALA]
    [(ladrillo? objeto) LADRILLO]
    [(base? objeto) BASE]
    [(indicador? objeto) (indicador-imagen objeto)]))

;objeto->posn: (tanque | bala | ladrillo | indicador) -> posn
;funcion extractora que permite obtener la posicion de una estructura
;objeto: representa la estructura a la que se desea extraer los datos
(define (objeto->posn objeto)
  (cond
    [(tanque? objeto) (tanque-posn objeto)]
    [(bala? objeto) (bala-posn objeto)]
    [(ladrillo? objeto) (ladrillo-posn objeto)]
    [(base? objeto) (base-posn objeto)]
    [(indicador? objeto) (indicador-posn objeto)]))

;objeto->velocidad: tanque | bala -> number
;funcion extractora que permite obtener la velocidad de una estructura
;objeto: representa la estructura de la que se desea extraer los datos
(define (objeto->velocidad objeto)
  (cond
    [(tanque? objeto) (tanque-velocidad objeto)]
    [(bala? objeto) VELOCIDAD_BALA]))

;objeto->tamaño: (tanque | bala | ladrillo) -> posn
;funcion extractora que permite obtener el tamaño de una estructura
;objeto: representa la estructura de la que se desea extarer los datos
(define (objeto->tamaño objeto)
  (cond
    [(tanque? objeto) (image-height JUG_ARRIBA)]
    [(bala? objeto) (image-height BALA)]
    [(ladrillo? objeto) (image-height LADRILLO)]
    [(base? objeto) (image-height BASE)]))


;;COLISIONES
;distancia: posn * posn -> number
;permite calcula la distancia entre dos objetos en el plano
(define (distancia posn1 posn2)
  (sqrt (+ (expt (- (posn-x posn1) (posn-x posn2)) 2) (expt (- (posn-y posn1) (posn-y posn2)) 2))))

;colision?: (tanque | bala | ladrillo) * (tanque | bala | ladrillo) -> boolean 
;permite saber si un objeto ha colisionado con otro
(define (colision? objeto1 objeto2)
  (< (distancia (objeto->posn objeto1) 
                (objeto->posn objeto2)) 
     (+ (/ (objeto->tamaño objeto1) 2)
        (/ (objeto->tamaño objeto2) 2))))

;colisionObjetoPared? (tanque | bala) -> boolean 
;permite detectar cuando un objeto colisiona con la pared
(define (colisionObjetoPared? objeto)
  (define posn_objeto (objeto->posn objeto))
  (define mitad_tamaño_objeto (/ (objeto->tamaño objeto) 2))
  (define x (posn-x posn_objeto))
  (define y (posn-y posn_objeto))
  (or (< x mitad_tamaño_objeto) 
      (> (+ x mitad_tamaño_objeto) ANCHO) 
      (< y mitad_tamaño_objeto) 
      (> (+ y mitad_tamaño_objeto) ALTO)))


;colisionObjetoLadrillos?: (tanque | bala) * list-of-ladrillo -> boolean
;permite detectar cuando un objeto coliciona con algun ladrillo de la lista de ladrillos
(define (colisionObjetoLadrillos? objeto ladrillos)
  (cond
    [(empty? ladrillos) false]
    [(colision? objeto (first ladrillos)) (first ladrillos)]
    [else (colisionObjetoLadrillos? objeto (rest ladrillos))]))

;colisionObjetoBalas?: (tanque | bala | ladrillo | base) * list-of-bala -> boolean 
;permite detectar cuando un objeto colisiona con alguna bala de la lista de balas
(define (colisionObjetoBalas? objeto balas)
  (cond
    [(empty? balas) false]
    [(and (bala? objeto)
          (colision? objeto (first balas))
          (not (string=? (bala-destino objeto) 
                         (bala-destino (first balas))))) (first balas)]
    [(and (tanque? objeto)
          (colision? objeto (first balas))
          (string=? (tanque-tipo objeto)
                    (bala-destino (first balas)))) (first balas)]
    [(and (ladrillo? objeto)
          (colision? objeto (first balas))) (first balas)]
    [(and (base? objeto)
          (colision? objeto (first balas))) (first balas)]
    [else (colisionObjetoBalas? objeto (rest balas))]))

;colisionObjetoTanques?: bala -> boolean
;permite detectar cuando un objeto colisiona con algun tanque de la lista de tanques
(define (colisionObjetoTanques? objeto tanques)
  (cond
    [(empty? tanques) false]
    [(and (bala? objeto)
          (colision? objeto (first tanques))
          (string=? (bala-destino objeto) 
                    (tanque-tipo (first tanques)))) (first tanques)]
    [(and (tanque? objeto)
          (colision? objeto (first tanques))
          (not (string=? (tanque-tipo objeto)
                         (tanque-tipo (first tanques))))) (first tanques)]
    [else (colisionObjetoTanques? objeto (rest tanques))]))

(define (colisionTanquesBalas? tanques balas)
  (cond
    [(empty? balas) false]
    [(colisionObjetoTanques? (first balas) tanques) true]
    [else (colisionTanquesBalas? tanques (rest balas))]))



;;MOVER TANQUES
;siguientePosicion: tanque -> posn
;determina la siguiente posicion de un objeto
;objeto: objeto al cual se desea calcular la siguiente posicion 
(define (siguientePosicion objeto nueva_direccion)
  (define x (posn-x (objeto->posn objeto)))
  (define y (posn-y (objeto->posn objeto)))
  (define velocidad (objeto->velocidad objeto))
  (cond
    [(string=? nueva_direccion "up") (make-posn x (- y velocidad))]
    [(string=? nueva_direccion "down") (make-posn x (+ y velocidad))]
    [(string=? nueva_direccion "left") (make-posn (- x velocidad) y)]
    [(string=? nueva_direccion "right") (make-posn (+ x velocidad) y)]
    [else (objeto->posn objeto)]))

;moverTanque: tanque * string * list-of-ladrillo -> tanque
;permite: cambiar la posicion anterior de un tanque  (moverlo)
(define (moverTanque tanque_a_mover direccion ladrillos)
  (define tipo (tanque-tipo tanque_a_mover))
  (define imagen (tanque-imagen tanque_a_mover))
  (define nueva_posn (siguientePosicion tanque_a_mover direccion))
  (define velocidad (tanque-velocidad tanque_a_mover))
  (define vidas (tanque-vidas tanque_a_mover))
  (define nuevo_tanque (tanque tipo imagen nueva_posn direccion velocidad vidas))
  (if (or (colisionObjetoPared? nuevo_tanque) 
          (colisionObjetoLadrillos? nuevo_tanque ladrillos)) 
      tanque_a_mover nuevo_tanque ))

;moverTanqueJugador: mundo * string -> mundo
;permite crear un nuevo mundo donde el tanque del jugador se ha movido
(define (moverTaqueJugador mundo_anterior direccion)
  (define jugador (mundo-jugador mundo_anterior))
  (define ladrillos (mundo-ladrillos mundo_anterior))
  (define nuevo_jugador (moverTanque jugador direccion ladrillos))
  (define base (mundo-base mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  (define enemigos (mundo-enemigos mundo_anterior))
  (define preguntas (mundo-preguntas mundo_anterior))
  (define pregunta (mundo-pregunta mundo_anterior))
  (mundo nuevo_jugador base balas ladrillos enemigos preguntas pregunta))

;moverTanqueEnemigo: tanque * list-of-string * list-of-ladrillo -> tanque
;permite mover un tanque dada una trayectoria lista de (ARRIBA | ABAJO | IZQUIERDA | DERECHA)
;detectando colision con ladrillos
(define (moverTanqueEnemigo tanque trayectoria ladrillos)
  (cond
    [(empty? trayectoria) tanque]
    [else (let ((tanque_movido (moverTanque tanque (first trayectoria) ladrillos)))
            (moverTanqueEnemigo tanque_movido (rest trayectoria) ladrillos))]))


;moverTanquesEnemigos: list-of-tanque * list-of-ladrillo -> list-of-tanque
;retorna una lista de tanque en una nueva posicion, teniendo en cuenta 
;que un tanque se mueve dependiendo de un valor aleatorio que regula la velocidad 
;del evento del tic
(define (moverTanquesEnemigos enemigos ladrillos)
  (define direccion (list-ref MOVIMIENTOS_ENEMIGO (random (length MOVIMIENTOS_ENEMIGO))))
  (define trayectoria (build-list DISTANCIA (lambda (x) direccion)))
  (cond
    [(empty? enemigos) empty]
    [(= 0 (random RANGO_MOVIMIENTO)) 
     (cons (moverTanqueEnemigo (first enemigos) trayectoria ladrillos) 
           (moverTanquesEnemigos (rest enemigos) ladrillos)) ]
    [else (cons (first enemigos) (moverTanquesEnemigos (rest enemigos) ladrillos))]))


;;DISPARAR BALAS
;colocarBala: tanque * list-of-balas -> list-of-balas
;permite añadir balas a una lista de balas 
;permite crear balas desde la posicion del tanque que la dispara 
(define (colocarBala tanque balas)
  (define posn (tanque-posn tanque))
  (define tipo (tanque-tipo tanque))
  (define direccion (tanque-direccion tanque))
  (if (string=? tipo TIPO_JUGADOR)
      (append (list (bala posn direccion TIPO_ENEMIGO)) balas)
      (append (list (bala posn direccion TIPO_JUGADOR)) balas)))

;colocarBalaJugador: mundo * string -> mundo
;retorna un mundo donde hay una nueva bala disparada por el jugador
(define (colocarBalaJugador mundo_anterior)
  (define jugador (mundo-jugador mundo_anterior))
  (define base (mundo-base mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  ;se adiccionan nuevas balas a las balas que hay en el mundo anteiror
  (define nuevas_balas (colocarBala jugador balas))
  (define ladrillos (mundo-ladrillos mundo_anterior))
  (define enemigos (mundo-enemigos mundo_anterior))
  (define preguntas (mundo-preguntas mundo_anterior))
  (define pregunta (mundo-pregunta mundo_anterior))
  (mundo jugador base nuevas_balas ladrillos enemigos preguntas pregunta))

;colocarBalasEnemigos: tanque * list-of-balas -> list-of-balas
;permite colocar balas en la lista de balas, dependiendo de la posicion 
;y direccion de cada tanque enemigo
;la velocidad de cada disparo es regulada con un numero aleatorio
;ya que esta funcion se realiza con el evento del tick que tiene una frecuencia muy alta
(define (colocarBalasEnemigos enemigos balas)
  (cond
    [(empty? enemigos) balas]
    [(= 0 (random RANGO_DISPARO)) 
     (colocarBalasEnemigos 
      (rest enemigos) 
      (colocarBala (first enemigos) balas))]
    [else (colocarBalasEnemigos (rest enemigos) balas)]))


;;MOVER BALAS
;moverBala: bala -> bala
;permite cambiar la posicion de una bala (moverla)
(define (moverBala b)
  (define direccion (bala-direccion b))
  (define destino (bala-destino b))
  (define posn_nueva (siguientePosicion b direccion))
  (bala posn_nueva direccion destino))

;moverBalas:  list-of-balas -> list-of-balas 
;permite cambiar la posicion de una lista de balas 
(define (moverBalas balas)
  (cond 
    [(empty? balas) empty]
    [else (cons (moverBala (first balas)) (moverBalas (rest balas)))]))


;ELIMINAR BALAS
;eliminarBalas: list-of-bala * list-of-ladrillo * list-of-bala * list-of-tanque * tanque * base -> list-of-bala
;permite eliminar aquellas balas de la lista de balas que choquen contra un pared, un ladrillo
(define (eliminarBalas balas ladrillos copia_balas jugador base)
  (cond 
    [(empty? balas) empty]
    [(colisionObjetoPared? (first balas)) (eliminarBalas (rest balas) ladrillos copia_balas jugador base)]
    [(colisionObjetoLadrillos? (first balas) ladrillos) (eliminarBalas (rest balas) ladrillos copia_balas jugador base)]
    [(colisionObjetoBalas? (first balas) copia_balas) (eliminarBalas (rest balas) ladrillos copia_balas jugador base)]
    [(colisionObjetoBalas? jugador (list (first balas))) (eliminarBalas (rest balas) ladrillos copia_balas jugador base)]
    [(colisionObjetoBalas? base (list (first balas))) (eliminarBalas (rest balas) ladrillos copia_balas jugador base)]
    [else (cons (first balas) (eliminarBalas (rest balas) ladrillos copia_balas jugador base))]))

(define (eliminarBalasAux balas enemigos)
  (cond
    [(empty? balas) empty]
    [(colisionObjetoTanques? (first balas) enemigos) (eliminarBalasAux (rest balas) enemigos)]
    [else (cons (first balas) (eliminarBalasAux (rest balas) enemigos))]))

;ELIMINAR LADRILLOS
;eliminarLadrillos: list-of-ladrillo * list-of-bala -> list-of-ladrillo
;permite eliminar aquellos ladrillos que son colisionados con alguna bala de la lista de balas
(define (eliminarLadrillos ladrillos balas)
  (cond
    [(empty? ladrillos) empty]
    [(colisionObjetoBalas? (first ladrillos) balas) (eliminarLadrillos (rest ladrillos) balas)]
    [else (cons (first ladrillos) (eliminarLadrillos (rest ladrillos) balas))]))

;ELIMINAR ENEMIGOS
;eliminarEnemigos: list-of-tanque -> list-of-tanque
;permite eliminar tanque que han perdido todas sus vidas 
(define (eliminarEnemigos enemigos)
  (cond
    [(empty? enemigos) empty]
    [(= 0 (tanque-vidas (first enemigos))) (eliminarEnemigos (rest enemigos))]
    [else (cons (first enemigos) (eliminarEnemigos (rest enemigos)))]))

;QUITAR VIDAS JUGADOR, ENEMIGOS O BASE DEL JUGADOR
;quitarVidaTanque tanque -> tanque
;permite restarle una vida a un tanque que haya sido afectado por una bala 
;de la lista de balas
(define (quitarVidaTanque tanque_anterior balas)
  (define tipo (tanque-tipo tanque_anterior))
  (define imagen (tanque-imagen tanque_anterior))
  (define posn (tanque-posn tanque_anterior))
  (define direccion (tanque-direccion tanque_anterior))
  (define velocidad (tanque-velocidad tanque_anterior))
  (define vidas (tanque-vidas tanque_anterior))
  (cond
    [(colisionObjetoBalas? tanque_anterior balas) 
     (tanque tipo imagen posn direccion velocidad (- vidas 1))]
    [else tanque_anterior]))

;quitarVidaTanques: list-of-tanque -> list-of-tanque
;permite restarle uan vida a cada tanque que es afectado por una bala de la lista de balas
(define (quitarVidaTanques tanques balas)
  (cond
    [(empty? tanques) empty]
    [else (cons (quitarVidaTanque (first tanques) balas)
                (quitarVidaTanques (rest tanques) balas))]))

(define (quitarVidaEnemigos tanques balas pregunta seleccion)
  (define respuesta (pregunta-respuesta pregunta))
  (if (string=? respuesta seleccion)
      (quitarVidaTanques tanques balas)
      tanques))

;quitarVidasBaseJugador: base * list-of-balas -> base
;permite restarle una vida a la base cuando es afectada por una bala
(define (quitarVidaBase base_anterior balas)
  (define posn (base-posn base_anterior))
  (define vidas (base-vidas base_anterior))
  (if (colisionObjetoBalas? base_anterior balas)
      (base posn (- vidas 1))
      base_anterior))

;;ON-KEY
;direccion?: string -> boolean
;determina si lo que recibe como paremtro es una direccion que permita mover al jugador
(define (direccion? dir)
  (or (string=? dir "up") 
      (string=? dir "down") 
      (string=? dir "left") 
      (string=? dir "right")))

;respuesta?: string -> boolean
;determina si lo que recibe como parametro es una respuesta dada a una pregunta 
;por el jugador
(define (respuesta? respuesta)
  (cond
    [(string=? respuesta "1") true]
    [(string=? respuesta "2") true]
    [(string=? respuesta "3") true]
    [(string=? respuesta "4") true]
    [else false]))

;actualizarPreguntas: pregunta * list-of-pregunta -> list-of-pregunta
;permite actualizar el atributo "preguntas" de la estructura mundo, si el jugador
;responde correctamente la pregunta que se encuntra en el atributo "pregunta" 
;de la estructura mundo, entonces esta pregunta es eliminada de la lista
;"preguntas". si el jugador no responde correctamente la pregunta, entonces
;esta pregunta sera colocada al final de la lista de preguntas
(define (actualizarPreguntas pregunta preguntas seleccion)
  (define respuesta (pregunta-respuesta pregunta))
  ;;si se toma en cuenta esta validacion, cuando la lista de preguntas 
  ;;este vacia , entonces el programa arrojara un erro
;  (if (equal? respuesta seleccion)
;      (remove pregunta preguntas)
;      (append (remove pregunta preguntas) (list pregunta)))
  
  (append (remove pregunta preguntas) (list pregunta)))

;evaluarPregunta: mundo * string -> mundo
;retorna un mundo donde ya se ha respondido a la pregunta 
;por lo tanto en el atributo "pregunta" del mundo , ya no hay 
;una pregunta
(define (evaluarPregunta mundo_anterior evento_tecla)
  (define jugador (mundo-jugador mundo_anterior))
  (define base (mundo-base mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  (define ladrillos (mundo-ladrillos mundo_anterior))
  (define enemigos (mundo-enemigos mundo_anterior))
  (define preguntas (mundo-preguntas mundo_anterior))
  (define pregunta (mundo-pregunta mundo_anterior))
  
  (define preguntas_nuevas (actualizarPreguntas pregunta preguntas evento_tecla))
  
  (define balas_restantes (eliminarBalasAux balas enemigos))
  
  (define enemigos_sin_vidas (quitarVidaEnemigos enemigos balas pregunta evento_tecla))
  
  (define enemigos_restantes (eliminarEnemigos enemigos_sin_vidas))
  
  (mundo jugador base  balas_restantes ladrillos enemigos_restantes preguntas_nuevas PREGUNTA_VACIA))

;cambiarMundoPorTeclado: mundo * string -> mundo
;retorna un mundo donde se ha movido el tanque si el usuario preciona alguna direccion del teclado
;retorna un mundo donde hay una bala si el usuario presiona la tecla espacio
(define (cambiarMundoPorTeclado mundo_anterior evento_tecla)
  (cond
    [(direccion? evento_tecla) 
     (moverTaqueJugador mundo_anterior evento_tecla)]
    [(string=? evento_tecla " ") 
     (colocarBalaJugador mundo_anterior)]
    [(respuesta? evento_tecla) (evaluarPregunta mundo_anterior evento_tecla)]
    [else mundo_anterior]))


;ON-TICK
;cambiarMundoPorTick: mundo -> mundo
;permite cambiar el mundo dependiendo del evento del tick
(define (cambiarMundoPorTick mundo_anterior)
  (define enemigos (mundo-enemigos mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  (if (colisionTanquesBalas? enemigos balas)
      (colocarUnaPreguntaEnElMundo mundo_anterior)
      (colocarMundoSinPreunta mundo_anterior)))

;colocarUnaPreguntaEnElMundo: mundo -> mundo
;permite colocar una pregunta en el atributo "pregunta" del mundo 
;retorna un mundo donde hay una pregunta
(define (colocarUnaPreguntaEnElMundo mundo_anterior)
  (define jugador (mundo-jugador mundo_anterior))
  (define base (mundo-base mundo_anterior))
  (define ladrillos (mundo-ladrillos mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  (define enemigos (mundo-enemigos mundo_anterior))
  (define preguntas (mundo-preguntas mundo_anterior))
  (define pregunta (first preguntas))
  (mundo jugador base balas ladrillos enemigos  preguntas pregunta))

;colocarMundoSinPregunta: mundo -> mundo
;permite colocar un mundo donde no hay preguntas para responder
(define (colocarMundoSinPreunta mundo_anterior)
  (define jugador (mundo-jugador mundo_anterior))
  (define base (mundo-base mundo_anterior))
  (define ladrillos (mundo-ladrillos mundo_anterior))
  (define balas (mundo-balas mundo_anterior))
  (define enemigos (mundo-enemigos mundo_anterior))
  (define preguntas (mundo-preguntas mundo_anterior))
  (define pregunta (mundo-pregunta mundo_anterior))
  
  (define balas_movidas (moverBalas balas))
  
  (define balas_restantes (eliminarBalas balas_movidas ladrillos balas_movidas jugador base))
  
  (define balas_nuevas (colocarBalasEnemigos enemigos balas_restantes))
  
  (define ladrillos_restantes (eliminarLadrillos ladrillos balas_movidas))
  
  (define enemigos_movidos (moverTanquesEnemigos enemigos ladrillos_restantes))
  
  (define base_sin_vidas (quitarVidaBase base balas_movidas))
  
  (define jugador_sin_vidas (quitarVidaTanque jugador balas_movidas))
  
  (mundo jugador_sin_vidas base_sin_vidas balas_nuevas ladrillos_restantes enemigos_movidos preguntas pregunta))


;;FIN DEL JUEGO
;terminarJuego?: mundo -> boolean
;permite finalizar el juego
(define (terminarJuego? mundo)
  (define vidas_jugador (tanque-vidas (mundo-jugador mundo)))
  (define vidas_base (base-vidas (mundo-base mundo)))
  (define num_enemigos (length (mundo-enemigos mundo)))
  (cond
    [(= 0 vidas_jugador) true]
    [(= 0 vidas_base) true]
    [(= 0 num_enemigos) true]
    [else false]))

;;==============================> EVENTOS <==================================
(big-bang MUNDO_INICIAL 
          (on-key cambiarMundoPorTeclado)
          (on-tick cambiarMundoPorTick VELOCIDAD_TICK)
          (to-draw pintarMundo)
          (stop-when terminarJuego?)
          (name "Thinking Tank"))


