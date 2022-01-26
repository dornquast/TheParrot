********************************
*                              *
*        THE PARROT            *
*                              *
* By Matthew Dornquast (C)1984 *
* This is the Sourcecode for   *
* the PARROT.  This source     *
* assembles with the Merlin    *
* Assembler.                   *
********************************
            LST    OFF
            ORG    $8000
ADDR        =      $0              $1
ADDR2       =      $2              $3
LEN         =      $4
BITSTAT     =      $5
XCOORD      =      $6
YSAVE       =      $7
SUM         =      $8              $9

X           =      $24
Y           =      $25

CR          =      $8D
POS         =      $90
TAB         =      $94

BUFFER      =      $4000           ;The move this lower for bigger record buffer.
*                        ;The end of the buffer is ALLWAYS $8000
CASINPUT    =      $C060

HGR         =      $F3E2
HPOS        =      $F411
HLIN        =      $F53A
HCOLOR      =      $F6F0
VTAB        =      $FC22
HOME        =      $FC58
INIT        =      $FB2F
COUT        =      $FDED
SETVID      =      $FE93
SETKBD      =      $FE89
PRINTBYT    =      $FDDA

*Main menu
            JSR    PRINT
            ASC    "1"00          ;Turn off videx 80 columns.
MAINMENU    JSR    HOME
            JSR    PRINT
            DFB    POS,1,7
            ASC    "+----------------------+"
            DFB    CR,TAB,7
            ASC    "|      THE PARROT      |"
            DFB    CR,TAB,7
            ASC    "| BY MATTHEW DORNQUAST |"
            DFB    CR,TAB,7
            ASC    "|   OF SOFTWORKS INC.  |"
            DFB    CR,TAB,7
            ASC    "+----------------------+"8D8D
            DFB    TAB,7
            ASC    "[R] RECORD INTO BUFFER"8D
            DFB    TAB,7
            ASC    "[P] PLAY BACK BUFFER"8D
            DFB    TAB,7
            ASC    "[G] GRAPH THE BUFFER"8D
            DFB    TAB,7
            ASC    "[E] ERASE THE BUFFER"8D
            DFB    TAB,7
            ASC    "[S] SAVE BUFFER TO DISK"8D
            DFB    TAB,7
            ASC    "[L] LOAD A BUFFER"8D
            DFB    TAB,7
            ASC    "[M] MAKE A PLAYFILE"8D
            DFB    TAB,7
            ASC    "[Q] QUIT TO BASIC"8D
            DFB    CR,TAB,14
            ASC    "WHICH [?]"00
MENULOP0    JSR    GETKEY
            LDX    #ENDMENU-MENU-3
MENULOOP    CMP    MENU,X          ;Did they want this option?
            BEQ    MENU2
            DEX
            DEX
            DEX
            BPL    MENULOOP        ;Branch if more options  not checked.
            BMI    MENULOP0
MENU2       INX
            LDA    MENU,X
            STA    MENU3+1
            INX
            LDA    MENU,X
            STA    MENU3+2
MENU3       JSR:   $0
            JMP    MAINMENU
MENU        DFB    "R",#<RECORD,#>RECORD
            DFB    "P",#<PLAY,#>PLAY
            DFB    "S",#<SAVE,#>SAVE
            DFB    "L",#<LOAD,#>LOAD
            DFB    "M",#<MAKEFILE,#>MAKEFILE
            DFB    "E",#<ERASE,#>ERASE
            DFB    "Q",#<QUIT,#>QUIT
            DFB    "G",#<GRAPH,#>GRAPH
ENDMENU

RECORD      JSR    HOME
            JSR    PRINT
            DFB    POS,4,0
            ASC    "<<< PRESS ANY KEY TO START RECORDING >>>"
            DFB    POS,10,0
            ASC    "  AT THIS POINT, THE CLEARER YOU CAN GET"
            ASC    "THE SPEAKER TO SOUND WITH YOUR INPUT THE"
            ASC    "BETTER YOUR MEMORY RECORDING WILL SOUND!"
            ASC    "PRESS A KEY WHEN YOU ARE DONE RECORDING."
            DFB    POS,19,0
            ASC    "<TWO BEEPS WILL SOUND WHEN THE TIMES UP>"00
            JSR    PLAYKEY
            LDA    #>BUFFER        ;Setup the buffer's starting address.
            STA    RECBUF+2
            LDA    #<BUFFER
            STA    RECBUF+1
            JMP    PAGEHOP

            DS     0-*&255
PAGEHOP     LDA    CASINPUT        ;Setup base bit, on or off
            AND    #$80            ;Start recording into memory
            STA    BITSTAT
            LDX    #0              ;Buffer position
RLOOP       LDY    #0
RLOOP2      LDA    CASINPUT
            AND    #$80            ;Same stat?
            CMP    BITSTAT
            BNE    SAVESTAT        ;branch if not.
            INY
            BNE    RLOOP2          ;allways branch.
SAVESTAT    STA    BITSTAT
            TYA
RECBUF      STA:   $0,X
            INX
            BNE    RLOOP
            BIT    $C000
            BMI    RECBUF2
            INC    RECBUF+2
            BPL    RLOOP           ;Branch if your not done recording.
            JSR    PRINT
            DFB    $87,$87,0
RECBUF2     BIT    $C010
            RTS                    ;Return to main menu

PLAY        JSR    PRINT
            DFB    POS,18,8
            ASC    "[PRESS A KEY TO STOP]"00
            LDA    #>BUFFER
            STA    PLAYBUF+2
            LDA    #<BUFFER
            STA    PLAYBUF+1
            LDX    #0
PLAYBUF0    BIT    $C000
            BPL    PLAYBUF
            BIT    $C010
            RTS
PLAYBUF     LDY:   $0,X
            BEQ    WAIT
PWAIT       NOP
            NOP
            NOP
            NOP
            CPX    $0
            DEY
            BNE    PWAIT
            STA    $C030           ;This take's 4 cycles.
HOP         INX
            BNE    PLAYBUF0
            INC    PLAYBUF+2
            BPL    PLAYBUF0
            RTS                    ;Return to main menu.
WAIT        NOP
            NOP
            NOP
            NOP
            CPX    $0
            DEY
            BNE    WAIT
            BEQ    HOP

*Play casette input through speaker while
*Waiting for a keypress.
PLAYKEY     LDA    CASINPUT
            AND    #$80
            STA    BITSTAT
PREPARE     LDA    CASINPUT
            AND    #%10000000
            CMP    BITSTAT
            BEQ    PAUSE
            LDX    $C030
            STA    BITSTAT
PAUSE       LDA    $C000
            BPL    PREPARE
            BIT    $C010
            RTS


*This routine gets a line of data
*(AY) points to data's destination
*(X)  is the length of data allowed.
GETLINE     STA    ADDR+1          ;Setup pointers.
            STY    ADDR
            DEX
            STX    LEN
            LDY    LEN             ;Now erase input buffer with proper character
            LDA    BACKCHAR        ;This is the proper char
GETLIN0     STA    (ADDR),Y
            DEY                    ;Erased whole buffer?
            BPL    GETLIN0         ;Branch if not.
            INY
GETLNL1     LDA    #"_"            ;Output cursor
            JSR    COUT
            JSR    GETKEY          ;Wait for a char.

            PHA                    ;Make keyclick noise.
            TYA
            PHA
            LDX    #12             ;Length of key's click
GETLNL3     LDY    #230            ;Pitch of key's click
GETLNL4     DEY
            BNE    GETLNL4
            BIT    $C030
            LDY    #18             ;Volume of key's click
GETLNL5     DEY
            BNE    GETLNL5
            BIT    $C030
            DEX                    ;Is the tone done?
            BNE    GETLNL3         ;Branch if not
            JSR    PRINT           ;Erase the cursor
            DFB    $88," ",$88,0
            PLA                    ;Restore registers
            TAY
            PLA
            CMP    #$8D            ;Are they done entering data?
            BEQ    GETLNCR         ;Branch if so
            CMP    #$88            ;Do they want to backspace?
            BEQ    BCKSPACE        ;Branch if so
            CPY    LEN             ;Are they at the limit?
            BCS    GETLNL1         ;Branch if so
            JSR    COUT            ;Print character to screen
            STA    (ADDR),Y        ;Save it in buffer
            INY                    ;Goto next position in buffer
            BNE    GETLNL1         ;Branch always
GETLNCR     STY    LEN             ;Save length of input
            CPY    #0
            BEQ    GETLNCR2        ;Branch if Y is zero
            CLC                    ;CLC means data was entered
            RTS
GETLNCR2    SEC                    ;SEC means they hit CR right away
            RTS
BCKSPACE    CPY    #0              ;Have they backed up all the way?
            BEQ    GETLNL1         ;Branch if so
            JSR    PRINT           ;Back up 1 char
BACKCHAR    =      *+1
            DFB    $88," ",$88,0
            LDA    BACKCHAR        ;Get char to put in buffer.
            STA    (ADDR),Y        ;Erase old char in input buffer.
            DEY                    ;Back up input buf 1 place
            JMP    GETLNL1         ;Give'm the old cursor again

*This routine prints text after jsr.
*If tab is found, next byte is horz pos.
*If pos is found, next 2 bytes are screen pos.
PRINT       PLA
            STA    ADDR2
            PLA
            STA    ADDR2+1
            TYA
            PHA
            TXA
            PHA
            JSR    VTAB
PLOOP       JSR    NEXTCHAR
            BEQ    PDONE
            CMP    #TAB
            BEQ    TABIT
            CMP    #POS
            BEQ    POSIT
            JSR    COUT
            JMP    PLOOP
PDONE       PLA
            TAX
            PLA
            TAY
            LDA    ADDR2+1
            PHA
            LDA    ADDR2
            PHA
            RTS
NEXTCHAR    LDY    #0
            INC    ADDR2
            BNE    NEXTCHR2
            INC    ADDR2+1
NEXTCHR2    LDA    (ADDR2),Y
            RTS
POSIT       JSR    NEXTCHAR        ;Position output to y,x
            STA    Y
TABIT       JSR    NEXTCHAR        ;Tab output to x.
            STA    X
            JSR    VTAB
            JMP    PLOOP

*This routine get's a keypress.
GETKEY      LDA    $C000
            BPL    GETKEY
            BIT    $C010
            RTS

*This routine saves sound buffer to disk
SAVE        JSR    DISK
            JSR    PRINT
            DFB    $8D,$84
            ASC    "BSAVE"00
            JSR    PNAME
            JSR    PRINT
            ASC    ",A$4000,L$4000"8D00
            RTS
LOAD        JSR    DISK
            JSR    PRINT
            DFB    $8D,$84
            ASC    "BLOAD"00
            JSR    PNAME
            JSR    PRINT
            ASC    ",A$4000"8D00
            RTS

*This routine get's the filename
DISK        JSR    PRINT
            DFB    POS,22,0
            ASC    "ENTER THE FILENAME [RETURN] FOR CATALOG"8D
            ASC    "FILENAME:"00
            LDA    #>FILEBUF
            LDY    #<FILEBUF
            LDX    #30
            JSR    GETLINE
            BCS    DISK2
            RTS
DISK2       JSR    HOME
            JSR    PRINT
            DFB    $8D,$84
            ASC    "CATALOG"8D8D
            ASC    "<<PRESS A KEY>>>"8D00
            PLA                    ;Return to main menu
            PLA
            JMP    GETKEY
PNAME       JSR    PRINT

FILEBUF     DS     30
            HEX    00
            RTS

*This routine makes a playfile for buffer
MAKEFILE    LDY    #$3F            ;Move playdata before recording
MAKEFIL2    LDA    DATA,Y
            STA    $3FC0,Y
            DEY
            BPL    MAKEFIL2
            JSR    DISK            ;Get the filename
            JSR    PRINT
            DFB    $8D,$84
            ASC    "BSAVEPLAY."00
            JSR    PNAME
            LDA    #$FF            ;Find end of music
            STA    ADDR
            LDA    #$7F
            STA    ADDR+1
MAKE3       LDY    #0
            LDA    (ADDR),Y
            BNE    MAKE4
            DEC    ADDR
            LDA    ADDR
            CMP    #$FF
            BNE    MAKE3
            DEC    ADDR+1
            BNE    MAKE3
MAKE4       SEC                    ;Figure out length then
            LDA    ADDR
            SBC    #<BUFFER
            STA    ADDR            ;Save it
            LDA    ADDR+1
            SBC    #>BUFFER
            STA    ADDR+1
            CLC
            LDA    #$40
            ADC    ADDR
            STA    ADDR
            LDA    #0
            ADC    ADDR+1
            STA    ADDR+1
            JSR    PRINT
            ASC    ",A$3FC0,L$"00
            LDA    ADDR+1
            JSR    PRINTBYT
            LDA    ADDR
            JSR    PRINTBYT
            JSR    PRINT
            HEX    8D00
            RTS

DATA        LDA    #>BUFFER        ;$3FC0
            STA    $3FD7           ;$3FC2
            LDA    #<BUFFER        ;$3FC5
            STA    $3FD6           ;$3FC7
            LDX    #0              ;$3FCA
DATA2       BIT    $C000           ;$3FCC
            BPL    DATA3           ;$3FCF
            BIT    $C010           ;$3FD1
            RTS                    ;$3FD4
DATA3       LDY:   $0,X            ;$3FD5
            BEQ    DATA6           ;$3FD8
DATA4       NOP                    ;$3FDA
            NOP                    ;$3FDB
            NOP                    ;$3FDC
            NOP                    ;$3FDD
            CPX    $0              ;$3FDE
            DEY                    ;$3FE0
            BNE    DATA4           ;$3FE1
            STA    $C030           ;$3FE3
DATA5       INX                    ;$3FE6
            BNE    DATA2           ;$3FE7
            INC    $3FD7           ;$3FE9
            BPL    DATA2           ;$3FEC
            RTS                    ;$3FEE
DATA6       NOP                    ;$3FEF
            NOP                    ;$3FF0
            NOP                    ;$3FF1
            NOP                    ;$3FF2
            CPX    $0              ;$3FF3
            DEY                    ;$3FF5
            BNE    DATA6           ;$3FF6
            BEQ    DATA5           ;$3FF8
            NOP                    ;$3FF9
            NOP                    ;$3FFA
            NOP                    ;$3FFB
            NOP                    ;$3FFC
            NOP                    ;$3FFD
            NOP                    ;$3FFE
            NOP                    ;$3FFF

*This routine quits.
QUIT        JSR    $FC58
            JSR    PRINT
            ASC    "IF YOU WOULD LIKE THE SOURCECODE AND"8D
            ASC    "TECHNICAL DATA, SEND $15 TO:"8D8D
            ASC    "SOFTWORKS INC."8D
            ASC    "P.O. BOX 17264"8D
            ASC    "MPLS, MN 55417"8D00
            PLA
            PLA
            JMP    $E003

*Erase the voice buffer.
ERASE       LDA    #<BUFFER
            STA    ADDR
            LDA    #>BUFFER
            STA    ADDR+1
            LDY    #0
ERASE2      TYA
ERASE3      STA    (ADDR),Y
            INY
            BNE    ERASE3
            INC    ADDR+1
            BPL    ERASE2
            RTS

*This routine graphs the buffer
GRAPH       JSR    HGR
            LDX    #3
            JSR    HCOLOR
            JSR    HOME
            JSR    PRINT
            DFB    POS,20,0
            ASC    "USE ARROW KEYS TO PAGE THROUGH BUFFER."8D
            ASC    "PRESS [RETURN] WHEN YOU ARE DONE"8D00
            LDA    #<BUFFER
            STA    ADDR
            LDA    #>BUFFER
            STA    ADDR+1

GRAPH0      LDA    ADDR
            PHA
            LDA    ADDR+1
            PHA
            LDY    #0              ;Hi byte of x coord
            LDX    #0              ;Lo byte of x coord
            LDA    #128            ;Ycoord
            JSR    HPOS
            LDX    #$20            ;ERASE THE HIRES PAGE
            STX    GRAPH0B+2
            LDY    #0
            TYA
GRAPH0B     STA:   $0,Y
            INY
            BNE    GRAPH0B
            INC    GRAPH0B+2
            DEX
            BNE    GRAPH0B

            LDA    #0
            STA    XCOORD
GRAPH1      LDA    #0              ;0 the previous average
            STA    SUM
            STA    SUM+1
            LDY    #8              ;Get 8 bytes to avrg.
            STY    YSAVE
            DEY
            CLC
GRAPH1B     LDA    (ADDR),Y        ;Get new piece of data and add it to sum
            ADC    SUM
            STA    SUM
            LDA    #0
            ADC    SUM+1
            STA    SUM+1
            DEY                    ;Is all the data added?
            BPL    GRAPH1B         ;Branch if not
            LDY    #3              ;Divide by 8.
GRAPH1C     ASL    SUM+1           ;Divide by 2
            ROL    SUM             ;     "
            DEY
            BNE    GRAPH1C         ;Branch if not done
            LDA    SUM             ;Fetch average of the data
            LSR                    ;Divide by 2 (this is scale)
            STA    BITSTAT         ;Save it
            SEC
            LDA    #128            ;Inverse data
            SBC    BITSTAT
            TAY                    ;Ypos of line
            LDA    XCOORD          ;Lo byte of xcoord
            LDX    #0              ;Hi byte of xcoord.
            JSR    HLIN
            LDA    YSAVE
            CLC
            ADC    ADDR
            STA    ADDR
            LDA    #0
            ADC    ADDR+1
            STA    ADDR+1
            INC    XCOORD          ;Goto next horz row over
            BNE    GRAPH1
            PLA
            STA    ADDR+1
            PLA
            STA    ADDR
GRAPH3B     JSR    GETKEY
            CMP    #$8D            ;Do they want to quit?
            BNE    GRAPH4          ;Branch if not
            BIT    $C051
            RTS
GRAPH4      CMP    #$88            ;Do they want to move graph left?
            BNE    GRAPH5          ;Branch if not
            LDA    ADDR+1          ;Fetch hipage val
            CMP    #$40            ;Is it as far left as possiable?
            BEQ    GRAPH3B         ;Branch if so.
            SEC
            SBC    #4              ;Move Left 8 pages
            STA    ADDR+1          ;Save new one
            JMP    GRAPH0
GRAPH5      CMP    #$95            ;Do they want to move graph right?
            BNE    GRAPH3B         ;Branch if not
            LDA    ADDR+1
            CMP    #$78            ;Is it the end page?
            BEQ    GRAPH3B         ;Branch if so
            CLC
            ADC    #4
            STA    ADDR+1          ;Save new page
            JMP    GRAPH0
            SAV    THE             PARROT
