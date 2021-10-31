from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from strutils import contains,repeat
from os import findExe,sleep,getCurrentDir
from term import warn,say,sayPos,inv,clear,exitEcho
from terminal import terminalWidth,setCursorXPos,getch,cursorUp,eraseLine,showCursor,styledWriteLine,fgCyan
from strformat import fmt
import client

proc exec*(x:string,args:openArray[string]; stream = false) =
 if stream: discard waitForExit startProcess(x,args=args,options={poUsePath,poParentStreams})
 else: discard waitForExit startProcess(x,args=args,options={poUsePath})

proc exit(ctx:ptr handle; term = false) =
 if term: terminateDestroy ctx
 exitEcho()

proc init(parm:string,ctx: ptr handle) =
 let file = allocCStringArray ["loadfile", parm] #couldbe file,link,playlistfile
 var val: cint = 1
 checkError ctx.setOption("osc", formatFlag, addr val)
 checkError initialize ctx
 checkError ctx.cmd file

proc player*(parm:string) =
 let ctx = create()
 init parm, ctx
 var j = true
 var e = false
 var event = ctx.waitEvent 1000
 while true:
  if j: sayPos 4, "Playing"; cursorUp(); j = false
  event = ctx.waitEvent 1000
  if cast[eventID](event) == eventIDShutdown: break
  if cast[eventID](event) == eventIDIdle: break
  case getch():
   of 'p','m','P','M':
    warn "Paused/Muted",4
    cursorUp()
    terminateDestroy ctx
    sleep 500
    while true:
     case getch():
      of 'p','m','P','M':
       eraseLine()
       let ctx = create()
       init parm, ctx
       j = true
       break
      of 'r','R': e = true; break
      of 'q','Q': exit ctx
      else: inv()
   of '/':
    when defined linux: exec "amixer",["--quiet","set","PCM","7%+"]
    #when defined windows: exec "nircmd",["changesysvolume","5000"]
    warn "Volume+"
    sleep 500
    cursorUp()
    eraseLine()
   of 'r','R': terminateDestroy ctx; break
   of 'q','Q': exit ctx, term = true
   else: inv()
  if e: break

proc call*(sub:string; sect = ""; stat,link:string) =
 if link == "" or link.contains " ": warn "link dont exist or is invalid"; sleep 750
 else:
  clear()
  if sect == "": say fmt"PNimRP > {sub} > {stat}"
  else: say fmt"PNimRP > {sub} > {sect} > {stat}"
  sayPos 0,'-'.repeat(int terminalWidth() / 8) & '>'.repeat int terminalWidth() / 12
  player link
