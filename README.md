El següent text està escrit en català, si vols un altre idioma fes ús de la IA o aprèn l'idioma en el qual m'expresso.

El siguiente texto está escrito en catalán, si quieres otro idioma haz uso de la IA o aprende el idioma en el cual me expreso.

The following text is written la IA aprèn, if you want another language use the AI ​​or learn the language in which I express myself.

---

Aquest repositori alberga el contingut de https://avilagrijalva.github.io. Us ensenyaré pas a pas com tindre un blog semblant sense que tinguis cap mena de coneixement tecnològic anterior, el qual per cert jo no tinc.

# Creem la nostra carpeta amb el compilador de Luasmith

1. fegim el fitxer **luasmith** que el podem descarregar del seu autor [original](https://github.com/jaredkrinke/luasmith/).
2. Reorganitzem el contingut de la carpeta de la següent forma on *content* tindrà el contingut dels fitxers MarkDown més el fitxer **site.lua** on s'especifica la configuració de la pàgina web que es generarà a la carpeta *out*. Recomano tindre els fitxers .md sense espais i utilitzar els guions com alternativa perquè sino quan es generi l'URL apareixerà *%20* on hauria d'haver-hi un espai.
3. Executem `./luasmith blog` i trobarem els fitxers generats a la carpeta *out*. Podemos canviar *blog* per qualsevol altre tema com per exemple *catala*.

# Connectem el repositori de Github amb la nostra carpeta

1. Òbviament, ja tenim el repositori creat i **git** configurat al nostre ordinador.
2. Fem un seguit de comandaments:

|Comandament     |  Què fa   |
| --- | --- |
|  `git init`   |   Genera *.git*  |
| `git branch -M main`|Especifica l'ús de la branca **main**|
| `git add .`| Preparem els fitxers |
| `git config user.name "usuari"`| Configurem l'usuari |
| `git config user.email "correu@exemple.cat"`|Configurem el correu|

3. Tenim el repositori llest per pujar-lo a Github, però no tenim la connexió feta.
	1. Primer creem la clau SSH al nostre ordinador amb  `ssh-keygen -t ed25519 -C "correu@exemple.cat"`.
	2. Activem l'agent SSH i agreguem la nostra clau:
	`eval "$(ssh-agent -s)"`
	`ssh-add ~/.ssh/id_ed25519`
	3. Copiem la nostra clau sencera per després anar-hi a Github: `cat ~/.ssh/id_ed25519.pub`.
	4. Anem a *GitHub Settings > SSH and GPG keys > New SSH Key* i copiem la nostra clau única.

4. Li diem al nostre ordinador que faci ús de la connexió SSH amb `git remote set-url origin git@github.com:USUARI/PROJECTE.git`.
5. Confirmem la connexió amb Github mitjançant `ssh -T git@github.com`. 

# Pugem la nostra carpeta a Github

Amb els fitxers ja preparats de `git add .` guardem els canvis amb `git commit -m "el teu missatge"` i els pugem amb `git push -u origin main`.

Ja tenim tots els fitxers que volíem a Github, però *Github Pages* no és capaç de construir el lloc web quan els fitxers *.html* es troben dintre d'una subcarpeta. 
- Podem especificar amb **git** una branca per *gh-pages* amb `git subtree push --prefix out origin gh-pages` on **out** és la nostra carpeta on es troben els fitxers generats per *luasmith*.
- Li hem de dir a *Github Pages* que faci ús d'aquesta branca entrant a *Repository Settings > Pages > Deploy from branch > gh-pages*.

# Llestos

Ara cada cop que modifiquem els continguts de la carpeta *content* amb Obsidian.MD haurem d'executar el fitxer *luasmith* per generar els fitxers de la carpeta *out* que seran pujats a Github mitjançant **git**. 


|  Taula resum: |
| --- |
|   ./luasmith blog  |
| git add . |
| git commit -m "missatge"|
| git push -u origin main |

## Notes

Per la configuració del lloc (title & URL) han de coincidir en contingut **/content/site.lua** i **/themes/blog/theme.lua**:

| /content/site.lua        | /themes/blog/theme.lua    |
| ------------- |:-------------:|
| ```return {title = "Oriol Ávila Grijalva", url = "https://avilagrijalva.github.io/",}```      | ```local site = {title = "Oriol Ávila Grijalva", url = "https://avilagrijalva.github.io/",}``` |

---

