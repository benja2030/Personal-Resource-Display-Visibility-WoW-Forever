# PRD Visibility

Controls the visibility of the Personal Resource Display in WoW: Forever:
  - In combat: fully visible, with bar text.
  - Out of combat while health or resources are regenerating: half visible.
  - Out of combat with full bars: hidden.
All of this can be changed in the options.


INSTALLATION
------------
1. Put the PRDVisibility folder inside:
     World of Warcraft\_forever_\Interface\AddOns\
   (the game folder name may vary; it must be the WoW: Forever installation)
2. The result must look like this:
     ...\Interface\AddOns\PRDVisibility\PRDVisibility.toc
     ...\Interface\AddOns\PRDVisibility\PRDVisibility.lua
   Make sure there is no extra folder in between, like
   PRDVisibility\PRDVisibility\.
3. In Edit Mode, set the Personal Resource Display Visibility to "Always"
   and its Opacity to 100%. Turn on "Show Bar Text" if you want the bar
   text in combat.


OPTIONS AND COMMANDS
--------------------
Options are in the game menu: Options > AddOns > PRD Visibility.

  /prdv            opens the options window
  /prdv options    opens the page in the game's Options menu
  /prdv help       opens the help window
  /prdv status     shows the current state and why
  /prdv debug      shows the time since the last health/resource change


IF THE ADDON STOPS LOADING
--------------------------
After a WoW: Forever update, the addon may stop loading. To fix it:

1. At character select, open the AddOns list and find PRD Visibility.

2. If it says "Out of date":
   Check "Load out of date AddOns" at the top of the list. That's all.

3. If it says "Incompatible":
   a) Enter the game with any character and type this in chat:
        /dump select(4, GetBuildInfo())
      It prints a number, for example 16001.
   b) Open PRDVisibility.toc with Notepad.
   c) Replace the number in the first line with the one from step a):
        ## Interface: 16001
   d) Save the file and restart the game.

Important: never put an invented number like 00000 in that line. The game
marks it as Incompatible and the addon will not load at all.




# PRD Visibility (español)

Controla la visibilidad del Personal Resource Display en WoW: Forever:
  - En combate: totalmente visible, con el texto de las barras.
  - Fuera de combate mientras se regenera la vida o el recurso: a medias.
  - Fuera de combate con las barras llenas: oculto.
Todo esto se puede cambiar en las opciones.

Para ver el addon en español, usa el botón "Language" en las opciones y
escribe /reload.


INSTALACIÓN
-----------
1. Pon la carpeta PRDVisibility dentro de:
     World of Warcraft\_forever_\Interface\AddOns\
   (el nombre de la carpeta del juego puede variar; tiene que ser la
   instalación de WoW: Forever)
2. Tiene que quedar así:
     ...\Interface\AddOns\PRDVisibility\PRDVisibility.toc
     ...\Interface\AddOns\PRDVisibility\PRDVisibility.lua
   Revisa que no quede una carpeta de más en medio, como
   PRDVisibility\PRDVisibility\.
3. En el Modo Edición, deja la Visibilidad del Personal Resource Display en
   "Always" y su Opacidad en 100%. Activa "Show Bar Text" si quieres ver el
   texto de las barras en combate.


OPCIONES Y COMANDOS
-------------------
Las opciones están en el menú del juego: Opciones > AddOns > PRD Visibility.

  /prdv             abre la ventana de opciones
  /prdv opciones    abre la página en el menú de Opciones del juego
  /prdv ayuda       abre la ventana de ayuda
  /prdv estado      muestra el estado actual y el motivo
  /prdv debug       muestra el tiempo desde el último cambio de vida o recurso


SI EL ADDON DEJA DE CARGAR
--------------------------
Después de una actualización de WoW: Forever, el addon podría dejar de
cargar. Para arreglarlo:

1. En la selección de personaje, abre la lista de AddOns y busca
   PRD Visibility.

2. Si dice "Out of date" (desactualizado):
   Marca "Load out of date AddOns" arriba de la lista. Con eso basta.

3. Si dice "Incompatible":
   a) Entra al juego con cualquier personaje y escribe en el chat:
        /dump select(4, GetBuildInfo())
      Te mostrará un número, por ejemplo 16001.
   b) Abre PRDVisibility.toc con el Bloc de notas.
   c) Reemplaza el número de la primera línea por el del paso a):
        ## Interface: 16001
   d) Guarda el archivo y reinicia el juego.

Importante: nunca pongas un número inventado como 00000 en esa línea. El
juego lo marca como Incompatible y el addon no cargará.
