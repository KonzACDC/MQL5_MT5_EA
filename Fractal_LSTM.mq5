/ / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                             F r a c t a l . m q 5   |  
 / / |                                                 C o p y r i g h t   2 0 2 0 ,   M e t a Q u o t e s   S o f t w a r e   C o r p .   |  
 / / |                                                                                           h t t p s : / / w w w . m q l 5 . c o m   |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 # p r o p e r t y   c o p y r i g h t   " C o p y r i g h t   2 0 2 0 ,   M e t a Q u o t e s   S o f t w a r e   C o r p . "  
 # p r o p e r t y   l i n k             " h t t p s : / / w w w . m q l 5 . c o m "  
 # p r o p e r t y   v e r s i o n       " 1 . 0 0 "  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 # i n c l u d e   " N e u r o N e t . m q h "  
 # i n c l u d e   < T r a d e \ S y m b o l I n f o . m q h >  
 # i n c l u d e   < I n d i c a t o r s \ T i m e S e r i e s . m q h >  
 # i n c l u d e   < I n d i c a t o r s \ V o l u m e s . m q h >  
 # i n c l u d e   < I n d i c a t o r s \ O s c i l a t o r s . m q h >  
 / / - - -  
 # d e f i n e   F i l e N a m e                 S y m b . N a m e ( ) + " _ " + E n u m T o S t r i n g ( ( E N U M _ T I M E F R A M E S ) P e r i o d ( ) ) + " _ " + I n t e g e r T o S t r i n g ( H i s t o r y B a r s , 3 ) + S t r i n g S u b s t r ( _ _ F I L E _ _ , 0 , S t r i n g F i n d ( _ _ F I L E _ _ , " . " , 0 ) )  
 / / - - -  
 e n u m   E N U M _ S I G N A L  
     {  
       S e l l = - 1 ,  
       U n d e f i n e = 0 ,  
       B u y = 1  
     } ;  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |       i n p u t   p a r a m e t e r s                                                                                               |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 i n p u t   i n t                                     S t u d y P e r i o d   =     2 ;                         / / S t u d y   p e r i o d ,   y e a r s  
 i n p u t   u i n t                                   H i s t o r y B a r s   =     2 0 ;                         / / D e p t h   o f   h i s t o r y  
 E N U M _ T I M E F R A M E S                         T i m e F r a m e       =     P E R I O D _ C U R R E N T ;  
 / / - - -  
 i n p u t   g r o u p                                 " - - - -   R S I   - - - - "  
 i n p u t   i n t                                     R S I P e r i o d       =     1 4 ;                         / / P e r i o d  
 i n p u t   E N U M _ A P P L I E D _ P R I C E       R S I P r i c e         =     P R I C E _ C L O S E ;       / / A p p l i e d   p r i c e  
 / / - - -  
 i n p u t   g r o u p                                 " - - - -   C C I   - - - - "  
 i n p u t   i n t                                     C C I P e r i o d       =     1 4 ;                         / / P e r i o d  
 i n p u t   E N U M _ A P P L I E D _ P R I C E       C C I P r i c e         =     P R I C E _ T Y P I C A L ;   / / A p p l i e d   p r i c e  
 / / - - -  
 i n p u t   g r o u p                                 " - - - -   A T R   - - - - "  
 i n p u t   i n t                                     A T R P e r i o d       =     1 4 ;                         / / P e r i o d  
 / / - - -  
 i n p u t   g r o u p                                 " - - - -   M A C D   - - - - "  
 i n p u t   i n t                                     F a s t P e r i o d     =     1 2 ;                         / / F a s t  
 i n p u t   i n t                                     S l o w P e r i o d     =     2 6 ;                         / / S l o w  
 i n p u t   i n t                                     S i g n a l P e r i o d =     9 ;                           / / S i g n a l  
 i n p u t   E N U M _ A P P L I E D _ P R I C E       M A C D P r i c e       =     P R I C E _ C L O S E ;       / / A p p l i e d   p r i c e  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 C S y m b o l I n f o                   * S y m b ;  
 C i O p e n                             * O p e n ;  
 C i C l o s e                           * C l o s e ;  
 C i H i g h                             * H i g h ;  
 C i L o w                               * L o w ;  
 C i V o l u m e s                       * V o l u m e s ;  
 C i T i m e                             * T i m e ;  
 C N e t C o n v o l u t i o n           * N e t ;  
 C A r r a y D o u b l e                 * T e m p D a t a ;  
 C i R S I                               * R S I ;  
 C i C C I                               * C C I ;  
 C i A T R                               * A T R ;  
 C i M A C D                             * M A C D ;  
 / / - - -  
 d o u b l e                               d E r r o r ;  
 d o u b l e                               d U n d e f i n e ;  
 d o u b l e                               d F o r e c a s t ;  
 d o u b l e                               d P r e v S i g n a l ;  
 d a t e t i m e                           d t S t u d i e d ;  
 b o o l                                   b E v e n t S t u d y ;  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   E x p e r t   i n i t i a l i z a t i o n   f u n c t i o n                                                                       |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 i n t   O n I n i t ( )  
     {  
 / / - - -  
       S y m b = n e w   C S y m b o l I n f o ( ) ;  
       i f ( C h e c k P o i n t e r ( S y m b ) = = P O I N T E R _ I N V A L I D   | |   ! S y m b . N a m e ( _ S y m b o l ) )  
             r e t u r n   I N I T _ F A I L E D ;  
       S y m b . R e f r e s h ( ) ;  
 / / - - -  
       O p e n = n e w   C i O p e n ( ) ;  
       i f ( C h e c k P o i n t e r ( O p e n ) = = P O I N T E R _ I N V A L I D   | |   ! O p e n . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       C l o s e = n e w   C i C l o s e ( ) ;  
       i f ( C h e c k P o i n t e r ( C l o s e ) = = P O I N T E R _ I N V A L I D   | |   ! C l o s e . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       H i g h = n e w   C i H i g h ( ) ;  
       i f ( C h e c k P o i n t e r ( H i g h ) = = P O I N T E R _ I N V A L I D   | |   ! H i g h . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       L o w = n e w   C i L o w ( ) ;  
       i f ( C h e c k P o i n t e r ( L o w ) = = P O I N T E R _ I N V A L I D   | |   ! L o w . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       V o l u m e s = n e w   C i V o l u m e s ( ) ;  
       i f ( C h e c k P o i n t e r ( V o l u m e s ) = = P O I N T E R _ I N V A L I D   | |   ! V o l u m e s . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e , V O L U M E _ T I C K ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       T i m e = n e w   C i T i m e ( ) ;  
       i f ( C h e c k P o i n t e r ( T i m e ) = = P O I N T E R _ I N V A L I D   | |   ! T i m e . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       R S I = n e w   C i R S I ( ) ;  
       i f ( C h e c k P o i n t e r ( R S I ) = = P O I N T E R _ I N V A L I D   | |   ! R S I . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e , R S I P e r i o d , R S I P r i c e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       C C I = n e w   C i C C I ( ) ;  
       i f ( C h e c k P o i n t e r ( C C I ) = = P O I N T E R _ I N V A L I D   | |   ! C C I . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e , C C I P e r i o d , C C I P r i c e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       A T R = n e w   C i A T R ( ) ;  
       i f ( C h e c k P o i n t e r ( A T R ) = = P O I N T E R _ I N V A L I D   | |   ! A T R . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e , A T R P e r i o d ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       M A C D = n e w   C i M A C D ( ) ;  
       i f ( C h e c k P o i n t e r ( M A C D ) = = P O I N T E R _ I N V A L I D   | |   ! M A C D . C r e a t e ( S y m b . N a m e ( ) , T i m e F r a m e , F a s t P e r i o d , S l o w P e r i o d , S i g n a l P e r i o d , M A C D P r i c e ) )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       N e t = n e w   C N e t C o n v o l u t i o n ( N U L L ) ;  
       R e s e t L a s t E r r o r ( ) ;  
       i f ( C h e c k P o i n t e r ( N e t ) = = P O I N T E R _ I N V A L I D   | |   ! N e t . L o a d ( F i l e N a m e + " . n n w " , d E r r o r , d U n d e f i n e , d F o r e c a s t , d t S t u d i e d , f a l s e ) )  
           {  
             p r i n t f ( " % s   -   % d   - >   E r r o r   o f   r e a d   % s   p r e v   N e t   % d " , _ _ F U N C T I O N _ _ , _ _ L I N E _ _ , F i l e N a m e + " . n n w " , G e t L a s t E r r o r ( ) ) ;  
             C A r r a y O b j   * T o p o l o g y = n e w   C A r r a y O b j ( ) ;  
             i f ( C h e c k P o i n t e r ( T o p o l o g y ) = = P O I N T E R _ I N V A L I D )  
                   r e t u r n   I N I T _ F A I L E D ;  
             / / - - -  
             C L a y e r D e s c r i p t i o n   * d e s c = n e w   C L a y e r D e s c r i p t i o n ( ) ;  
             i f ( C h e c k P o i n t e r ( d e s c ) = = P O I N T E R _ I N V A L I D )  
                   r e t u r n   I N I T _ F A I L E D ;  
             d e s c . c o u n t = ( i n t ) H i s t o r y B a r s * 1 2 ;  
             d e s c . t y p e = d e f N e u r o n ;  
             i f ( ! T o p o l o g y . A d d ( d e s c ) )  
                   r e t u r n   I N I T _ F A I L E D ;  
             / / - - -  
             d e s c = n e w   C L a y e r D e s c r i p t i o n ( ) ;  
             i f ( C h e c k P o i n t e r ( d e s c ) = = P O I N T E R _ I N V A L I D )  
                   r e t u r n   I N I T _ F A I L E D ;  
             d e s c . c o u n t = 4 ;  
             d e s c . t y p e = d e f N e u r o n L S T M ;  
             d e s c . w i n d o w = ( i n t ) H i s t o r y B a r s * 1 2 ;  
             d e s c . s t e p = ( i n t ) H i s t o r y B a r s / 2 ;  
             i f ( ! T o p o l o g y . A d d ( d e s c ) )  
                   r e t u r n   I N I T _ F A I L E D ;  
             / / - - -  
             i n t   n = 1 0 0 0 ;  
             b o o l   r e s u l t = t r u e ;  
             f o r ( i n t   i = 0 ;   ( i < 4   & &   r e s u l t ) ;   i + + )  
                 {  
                   d e s c = n e w   C L a y e r D e s c r i p t i o n ( ) ;  
                   i f ( C h e c k P o i n t e r ( d e s c ) = = P O I N T E R _ I N V A L I D )  
                         r e t u r n   I N I T _ F A I L E D ;  
                   d e s c . c o u n t = n ;  
                   d e s c . t y p e = d e f N e u r o n ;  
                   r e s u l t = ( T o p o l o g y . A d d ( d e s c )   & &   r e s u l t ) ;  
                   n = ( i n t ) M a t h M a x ( n * 0 . 3 , 2 0 ) ;  
                 }  
             i f ( ! r e s u l t )  
                 {  
                   d e l e t e   T o p o l o g y ;  
                   r e t u r n   I N I T _ F A I L E D ;  
                 }  
             / / - - -  
             d e s c = n e w   C L a y e r D e s c r i p t i o n ( ) ;  
             i f ( C h e c k P o i n t e r ( d e s c ) = = P O I N T E R _ I N V A L I D )  
                   r e t u r n   I N I T _ F A I L E D ;  
             d e s c . c o u n t = 3 ;  
             d e s c . t y p e = d e f N e u r o n ;  
             i f ( ! T o p o l o g y . A d d ( d e s c ) )  
                   r e t u r n   I N I T _ F A I L E D ;  
             d e l e t e   N e t ;  
             N e t = n e w   C N e t C o n v o l u t i o n ( T o p o l o g y ) ;  
             d e l e t e   T o p o l o g y ;  
             i f ( C h e c k P o i n t e r ( N e t ) = = P O I N T E R _ I N V A L I D )  
                   r e t u r n   I N I T _ F A I L E D ;  
             d E r r o r = - 1 ;  
             d U n d e f i n e = 0 ;  
             d F o r e c a s t = 0 ;  
             d t S t u d i e d = 0 ;  
           }  
 / / - - -  
       T e m p D a t a = n e w   C A r r a y D o u b l e ( ) ;  
       i f ( C h e c k P o i n t e r ( T e m p D a t a ) = = P O I N T E R _ I N V A L I D )  
             r e t u r n   I N I T _ F A I L E D ;  
 / / - - -  
       b E v e n t S t u d y = E v e n t C h a r t C u s t o m ( C h a r t I D ( ) , 1 , ( l o n g ) M a t h M a x ( 0 , M a t h M i n ( i T i m e ( S y m b . N a m e ( ) , P E R I O D _ C U R R E N T , ( i n t ) ( 1 0 0 * N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r * ( d F o r e c a s t > = 7 0   ?   1   :   1 0 ) ) ) , d t S t u d i e d ) ) , 0 , " I n i t " ) ;  
 / / - - -  
       r e t u r n ( I N I T _ S U C C E E D E D ) ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   E x p e r t   d e i n i t i a l i z a t i o n   f u n c t i o n                                                                   |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   O n D e i n i t ( c o n s t   i n t   r e a s o n )  
     {  
 / / - - -  
       i f ( C h e c k P o i n t e r ( S y m b ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   S y m b ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( O p e n ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   O p e n ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( C l o s e ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   C l o s e ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( H i g h ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   H i g h ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( L o w ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   L o w ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( T i m e ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   T i m e ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( V o l u m e s ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   V o l u m e s ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( R S I ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   R S I ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( C C I ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   C C I ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( A T R ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   A T R ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( M A C D ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   M A C D ;  
 / / - - -  
       i f ( C h e c k P o i n t e r ( N e t ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   N e t ;  
       i f ( C h e c k P o i n t e r ( T e m p D a t a ) ! = P O I N T E R _ I N V A L I D )  
             d e l e t e   T e m p D a t a ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   E x p e r t   t i c k   f u n c t i o n                                                                                           |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   O n T i c k ( )  
     {  
 / / - - -  
       i f ( ! b E v e n t S t u d y   & &   ( d P r e v S i g n a l = = - 2   | |   d t S t u d i e d < S e r i e s I n f o I n t e g e r ( S y m b . N a m e ( ) , T i m e F r a m e , S E R I E S _ L A S T B A R _ D A T E ) ) )  
             b E v e n t S t u d y = E v e n t C h a r t C u s t o m ( C h a r t I D ( ) , 1 , ( l o n g ) M a t h M a x ( 0 , M a t h M i n ( i T i m e ( S y m b . N a m e ( ) , P E R I O D _ C U R R E N T , ( i n t ) ( 1 0 0 * N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r * ( d F o r e c a s t > = 7 0   ?   1   :   1 0 ) ) ) , d t S t u d i e d ) ) , 0 , " N e w   B a r " ) ;  
 / / - - -  
       C o m m e n t ( S t r i n g F o r m a t ( " K7>2  A>1KB8O  % s ;   P r e v S i g n a l   % . 5 f ;   >45;L  >1CG5=0  % s   - >   % s " , ( s t r i n g ) b E v e n t S t u d y , d P r e v S i g n a l , T i m e T o S t r i n g ( d t S t u d i e d ) , T i m e T o S t r i n g ( S e r i e s I n f o I n t e g e r ( S y m b . N a m e ( ) , T i m e F r a m e , S E R I E S _ L A S T B A R _ D A T E ) ) ) ) ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   T r a d e   f u n c t i o n                                                                                                       |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   O n T r a d e ( )  
     {  
 / / - - -  
  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   T r a d e T r a n s a c t i o n   f u n c t i o n                                                                                 |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   O n T r a d e T r a n s a c t i o n ( c o n s t   M q l T r a d e T r a n s a c t i o n &   t r a n s ,  
                                                 c o n s t   M q l T r a d e R e q u e s t &   r e q u e s t ,  
                                                 c o n s t   M q l T r a d e R e s u l t &   r e s u l t )  
     {  
 / / - - -  
  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |   C h a r t E v e n t   f u n c t i o n                                                                                             |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   O n C h a r t E v e n t ( c o n s t   i n t   i d ,  
                                     c o n s t   l o n g   & l p a r a m ,  
                                     c o n s t   d o u b l e   & d p a r a m ,  
                                     c o n s t   s t r i n g   & s p a r a m )  
     {  
 / / - - -  
       i f ( i d = = 1 0 0 1 )  
           {  
             T r a i n ( l p a r a m ) ;  
             b E v e n t S t u d y = f a l s e ;  
             O n T i c k ( ) ;  
           }  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   T r a i n ( d a t e t i m e   S t a r t T r a i n B a r = 0 )  
     {  
       i n t   c o u n t = 0 ;  
 / / - - -  
       M q l D a t e T i m e   s t a r t _ t i m e ;  
       T i m e C u r r e n t ( s t a r t _ t i m e ) ;  
       s t a r t _ t i m e . y e a r - = S t u d y P e r i o d ;  
       i f ( s t a r t _ t i m e . y e a r < = 0 )  
             s t a r t _ t i m e . y e a r = 1 9 0 0 ;  
       d a t e t i m e   s t _ t i m e = S t r u c t T o T i m e ( s t a r t _ t i m e ) ;  
       d t S t u d i e d = M a t h M a x ( S t a r t T r a i n B a r , s t _ t i m e ) ;  
 / / - - -  
       d o u b l e   p r e v _ u n = - 1 ;  
       d o u b l e   p r e v _ f o r = - 1 ;  
       d o u b l e   p r e v _ e r = - 1 ;  
       d a t e t i m e   b a r _ t i m e = 0 ;  
       b o o l   s t o p = I s S t o p p e d ( ) ;  
 / / - - -  
       M q l D a t e T i m e   s T i m e ;  
       d o  
           {  
             i n t   b a r s = ( i n t ) M a t h M i n ( B a r s ( S y m b . N a m e ( ) , T i m e F r a m e , d t S t u d i e d , T i m e C u r r e n t ( ) ) + H i s t o r y B a r s , B a r s ( S y m b . N a m e ( ) , T i m e F r a m e ) ) ;  
             p r e v _ u n = d U n d e f i n e ;  
             p r e v _ f o r = d F o r e c a s t ;  
             p r e v _ e r = d E r r o r ;  
             E N U M _ S I G N A L   b a r = U n d e f i n e ;  
             / / - - -  
             i f ( ! O p e n . B u f f e r R e s i z e ( b a r s )   | |   ! C l o s e . B u f f e r R e s i z e ( b a r s )   | |   ! H i g h . B u f f e r R e s i z e ( b a r s )   | |   ! L o w . B u f f e r R e s i z e ( b a r s )   | |   ! T i m e . B u f f e r R e s i z e ( b a r s )   | |  
                   ! R S I . B u f f e r R e s i z e ( b a r s )   | |   ! C C I . B u f f e r R e s i z e ( b a r s )   | |   ! A T R . B u f f e r R e s i z e ( b a r s )   | |   ! M A C D . B u f f e r R e s i z e ( b a r s )   | |   ! V o l u m e s . B u f f e r R e s i z e ( b a r s ) )  
                   b r e a k ;  
             O p e n . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             C l o s e . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             H i g h . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             L o w . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             V o l u m e s . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             T i m e . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             R S I . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             C C I . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             A T R . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             M A C D . R e f r e s h ( O B J _ A L L _ P E R I O D S ) ;  
             / / - - -  
             s t o p = I s S t o p p e d ( ) ;  
             b o o l   a d d _ l o o p = f a l s e ;  
             f o r ( i n t   i = ( i n t ) ( b a r s - M a t h M a x ( H i s t o r y B a r s , 0 ) - 1 ) ;   i > = 0   & &   ! s t o p ;   i - - )  
                 {  
                   s t r i n g   s = S t r i n g F o r m a t ( " S t u d y   - >   E r a   % d   - >   % . 2 f   - >   U n d e f i n e   % . 2 f % %   f o r a c a s t   % . 2 f % % \ n   % d   o f   % d   - >   % . 2 f % %   \ n E r r o r   % . 2 f \ n % s   - >   % . 2 f " , c o u n t , d E r r o r , d U n d e f i n e , d F o r e c a s t , b a r s - i + 1 , b a r s , ( d o u b l e ) ( b a r s - i + 1 . 0 ) / b a r s * 1 0 0 , N e t . g e t R e c e n t A v e r a g e E r r o r ( ) , E n u m T o S t r i n g ( D o u b l e T o S i g n a l ( d P r e v S i g n a l ) ) , d P r e v S i g n a l ) ;  
                   C o m m e n t ( s ) ;  
                   i f ( a d d _ l o o p   & &   i < ( i n t ) ( b a r s - M a t h M a x ( H i s t o r y B a r s , 0 ) - 1 )   & &   i > 1   & &   T i m e . G e t D a t a ( i ) > d t S t u d i e d   & &   d P r e v S i g n a l ! = - 2 )  
                       {  
                         T e m p D a t a . C l e a r ( ) ;  
                         b o o l   s e l l = ( H i g h . G e t D a t a ( i + 2 ) < H i g h . G e t D a t a ( i + 1 )   & &   H i g h . G e t D a t a ( i ) < H i g h . G e t D a t a ( i + 1 ) ) ;  
                         b o o l   b u y = ( L o w . G e t D a t a ( i + 2 ) < L o w . G e t D a t a ( i + 1 )   & &   L o w . G e t D a t a ( i ) < L o w . G e t D a t a ( i + 1 ) ) ;  
                         T e m p D a t a . A d d ( ( d o u b l e ) b u y ) ;  
                         T e m p D a t a . A d d ( ( d o u b l e ) s e l l ) ;  
                         T e m p D a t a . A d d ( ( d o u b l e ) ( ! b u y   & &   ! s e l l ) ) ;  
                         N e t . b a c k P r o p ( T e m p D a t a ) ;  
                         i f ( D o u b l e T o S i g n a l ( d P r e v S i g n a l ) ! = U n d e f i n e )  
                             {  
                               i f ( D o u b l e T o S i g n a l ( d P r e v S i g n a l ) = = D o u b l e T o S i g n a l ( T e m p D a t a . A t ( 0 ) ) )  
                                     d F o r e c a s t + = ( 1 0 0 - d F o r e c a s t ) / N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r ;  
                               e l s e  
                                     d F o r e c a s t - = d F o r e c a s t / N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r ;  
                               d U n d e f i n e - = d U n d e f i n e / N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r ;  
                             }  
                         e l s e  
                             {  
                               i f ( s e l l   | |   b u y )  
                                     d U n d e f i n e + = ( 1 0 0 - d U n d e f i n e ) / N e t . r e c e n t A v e r a g e S m o o t h i n g F a c t o r ;  
                             }  
                       }  
                   T e m p D a t a . C l e a r ( ) ;  
                   i n t   r = i + ( i n t ) H i s t o r y B a r s ;  
                   i f ( r > b a r s )  
                         c o n t i n u e ;  
                   / / - - -  
                   f o r ( i n t   b = 0 ;   b < ( i n t ) H i s t o r y B a r s ;   b + + )  
                       {  
                         i n t   b a r _ t = r + b ;  
                         d o u b l e   o p e n = O p e n . G e t D a t a ( b a r _ t ) ;  
                         T i m e T o S t r u c t ( T i m e . G e t D a t a ( b a r _ t ) , s T i m e ) ;  
                         d o u b l e   r s i = R S I . M a i n ( b a r _ t ) ;  
                         d o u b l e   c c i = C C I . M a i n ( b a r _ t ) ;  
                         d o u b l e   a t r = A T R . M a i n ( b a r _ t ) ;  
                         d o u b l e   m a c d = M A C D . M a i n ( b a r _ t ) ;  
                         d o u b l e   s i g n = M A C D . S i g n a l ( b a r _ t ) ;  
                         i f ( r s i = = E M P T Y _ V A L U E   | |   c c i = = E M P T Y _ V A L U E   | |   a t r = = E M P T Y _ V A L U E   | |   m a c d = = E M P T Y _ V A L U E   | |   s i g n = = E M P T Y _ V A L U E )  
                               c o n t i n u e ;  
                         / / - - -  
                         i f ( o p e n = = E M P T Y _ V A L U E   | |  
                               ! T e m p D a t a . A d d ( C l o s e . G e t D a t a ( b a r _ t ) - o p e n )   | |   ! T e m p D a t a . A d d ( H i g h . G e t D a t a ( b a r _ t ) - o p e n )   | |   ! T e m p D a t a . A d d ( L o w . G e t D a t a ( b a r _ t ) - o p e n )   | |   ! T e m p D a t a . A d d ( V o l u m e s . M a i n ( b a r _ t ) / 1 0 0 0 )   | |  
                               ! T e m p D a t a . A d d ( s T i m e . h o u r )   | |   ! T e m p D a t a . A d d ( s T i m e . d a y _ o f _ w e e k )   | |   ! T e m p D a t a . A d d ( s T i m e . m o n )   | |  
                               ! T e m p D a t a . A d d ( r s i )   | |   ! T e m p D a t a . A d d ( c c i )   | |   ! T e m p D a t a . A d d ( a t r )   | |   ! T e m p D a t a . A d d ( m a c d )   | |   ! T e m p D a t a . A d d ( s i g n ) )  
                               b r e a k ;  
                       }  
                   i f ( T e m p D a t a . T o t a l ( ) < ( i n t ) H i s t o r y B a r s * 1 2 )  
                         c o n t i n u e ;  
                   a d d _ l o o p = t r u e ;  
                   N e t . f e e d F o r w a r d ( T e m p D a t a ) ;  
                   N e t . g e t R e s u l t s ( T e m p D a t a ) ;  
                   s w i t c h ( T e m p D a t a . M a x i m u m ( 0 , 3 ) )  
                       {  
                         c a s e   0 :  
                               d P r e v S i g n a l = T e m p D a t a [ 0 ] ;  
                               b r e a k ;  
                         c a s e   1 :  
                               d P r e v S i g n a l = - T e m p D a t a [ 1 ] ;  
                               b r e a k ;  
                         d e f a u l t :  
                               d P r e v S i g n a l = 0 ;  
                               b r e a k ;  
                       }  
                   b a r _ t i m e = T i m e . G e t D a t a ( i ) ;  
                   i f ( i < 3 0 0 )  
                       {  
                         i f ( D o u b l e T o S i g n a l ( d P r e v S i g n a l ) = = U n d e f i n e )  
                               D e l e t e O b j e c t ( b a r _ t i m e ) ;  
                         e l s e  
                               D r a w O b j e c t ( b a r _ t i m e , d P r e v S i g n a l , H i g h . G e t D a t a ( i ) , L o w . G e t D a t a ( i ) ) ;  
                       }  
                   s t o p = I s S t o p p e d ( ) ;  
                 }  
             i f ( a d d _ l o o p )  
                   c o u n t + + ;  
             i f ( ! s t o p )  
                 {  
                   d E r r o r = N e t . g e t R e c e n t A v e r a g e E r r o r ( ) ;  
                   i f ( a d d _ l o o p )  
                       {  
                         N e t . S a v e ( F i l e N a m e + " . n n w " , d E r r o r , d U n d e f i n e , d F o r e c a s t , d t S t u d i e d , f a l s e ) ;  
                         p r i n t f ( " E r a   % d   - >   e r r o r   % . 2 f   % %   f o r e c a s t   % . 2 f " , c o u n t , d E r r o r , d F o r e c a s t ) ;  
                       }  
                   C h a r t S c r e e n S h o t ( 0 , F i l e N a m e + I n t e g e r T o S t r i n g ( c o u n t ) + " . p n g " , 7 5 0 , 4 0 0 ) ;  
                 }  
           }  
       w h i l e ( ( ! ( D o u b l e T o S i g n a l ( d P r e v S i g n a l ) ! = U n d e f i n e   | |   d F o r e c a s t > 7 0 )   | |   ! ( d E r r o r < 0 . 1   & &   M a t h A b s ( d E r r o r - p r e v _ e r ) < 0 . 0 1   & &   M a t h A b s ( d U n d e f i n e - p r e v _ u n ) < 0 . 1   & &   M a t h A b s ( d F o r e c a s t - p r e v _ f o r ) < 0 . 1 ) )   & &   ! s t o p ) ;  
       i f ( c o u n t > 0 )  
           {  
             d t S t u d i e d = b a r _ t i m e ;  
           }  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 E N U M _ S I G N A L   D o u b l e T o S i g n a l ( d o u b l e   v a l u e )  
     {  
       v a l u e = N o r m a l i z e D o u b l e ( v a l u e , 1 ) ;  
       i f ( M a t h A b s ( v a l u e ) > 1   | |   M a t h A b s ( v a l u e ) < = 0 )  
             r e t u r n   U n d e f i n e ;  
       i f ( v a l u e > 0 )  
             r e t u r n   B u y ;  
       e l s e  
             r e t u r n   S e l l ;  
 / / - - -  
       r e t u r n   U n d e f i n e ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   D r a w O b j e c t ( d a t e t i m e   t i m e ,   d o u b l e   s i g n a l ,   d o u b l e   h i g h ,   d o u b l e   l o w )  
     {  
       d o u b l e   p r i c e = 0 ;  
       i n t   a r r o w = 0 ;  
       c o l o r   c l r = 0 ;  
       E N U M _ A R R O W _ A N C H O R   a n c h = A N C H O R _ B O T T O M ;  
       s w i t c h ( D o u b l e T o S i g n a l ( s i g n a l ) )  
           {  
             c a s e   B u y :  
                   p r i c e = l o w ;  
                   a r r o w = 2 1 7 ;  
                   c l r = c l r B l u e ;  
                   a n c h = A N C H O R _ T O P ;  
                   b r e a k ;  
             c a s e   S e l l :  
                   p r i c e = h i g h ;  
                   a r r o w = 2 1 8 ;  
                   c l r = c l r R e d ;  
                   a n c h = A N C H O R _ B O T T O M ;  
                   b r e a k ;  
           }  
       i f ( p r i c e = = 0   | |   a r r o w = = 0 )  
             r e t u r n ;  
 / / - - -  
       s t r i n g   n a m e = T i m e T o S t r i n g ( t i m e ) ;  
       i f ( O b j e c t F i n d ( 0 , n a m e ) < 0 )  
           {  
             R e s e t L a s t E r r o r ( ) ;  
             i f ( ! O b j e c t C r e a t e ( 0 , n a m e , O B J _ A R R O W , 0 , t i m e , 0 ) )  
                 {  
                   p r i n t f ( " E r r o r   o f   c r e a t i n g   o b j e c t   % d " , G e t L a s t E r r o r ( ) ) ;  
                   r e t u r n ;  
                 }  
           }  
 / / p r i n t f ( " % s   -   % d   - >   % s " , _ _ F U N C T I O N _ _ , _ _ L I N E _ _ , n a m e ) ;  
       O b j e c t S e t D o u b l e ( 0 , n a m e , O B J P R O P _ P R I C E , p r i c e ) ;  
       O b j e c t S e t I n t e g e r ( 0 , n a m e , O B J P R O P _ A R R O W C O D E , a r r o w ) ;  
       O b j e c t S e t I n t e g e r ( 0 , n a m e , O B J P R O P _ C O L O R , c l r ) ;  
       O b j e c t S e t I n t e g e r ( 0 , n a m e , O B J P R O P _ A N C H O R , a n c h ) ;  
       O b j e c t S e t S t r i n g ( 0 , n a m e , O B J P R O P _ T O O L T I P , E n u m T o S t r i n g ( D o u b l e T o S i g n a l ( s i g n a l ) ) + "   " + D o u b l e T o S t r i n g ( s i g n a l , 5 ) ) ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 / / |                                                                                                                                     |  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 v o i d   D e l e t e O b j e c t ( d a t e t i m e   t i m e )  
     {  
       s t r i n g   n a m e = T i m e T o S t r i n g ( t i m e ) ;  
       i f ( O b j e c t F i n d ( 0 , n a m e ) > = 0 )  
             O b j e c t D e l e t e ( 0 , n a m e ) ;  
     }  
 / / + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +  
 