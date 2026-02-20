---
title: Colofó
description: 
date: 2026-01-18
update: 
keywords: [blog]
---

Quan vaig sentir parlar per primera vegada d'aquest tipus de pàgines, no vaig entendre realment a què es referien. Per a mi, «el colofó» és un text al final d'un document que proporciona informació sobre la seva autoria i impressió.

Vaig haver de fer una mica de recerca i entendre que aquest colofó es troba en una pàgina separada per descriure les eines, els sistemes i les fonts utilitzats per crear el lloc web i per reconèixer els recursos emprats per produir-lo.

Per tant, inclou el programari, el maquinari i els llenguatges de programació utilitzats en la preparació dels textos i en la creació del lloc, així com el tipus de servidor en què s'executa. 

Tot el seu contingut està escrit en arxius Markdown mitjançant qualsevol editor de textos, actualment utilitzo *VSCodium*.

Posteriorment executo el fitxer *luasmith* per generar els fitxers de la carpeta *out* que seran pujats a Github mitjançant **git**.

## Infraestructura

- **Registrador del domini**: Github Pages.
- **Allotjament**: Github Pages.
- **Repositori**: https://github.com/avilagrijalva/avilagrijalva.github.io
- **Desplegament**: [Github Actions](https://github.com/avilagrijalva/avilagrijalva.github.io/blob/main/.github/workflows/static.yml).

## Stack tecnològic

- **Generador del lloc**: [Luasmith](https://github.com/jaredkrinke/luasmith/)
- **Tema**: Tema original de [blog](https://github.com/jaredkrinke/luasmith/tree/main/themes/blog), el que ve per defecte amb *Luasmith*, però ara molt modificat que jo anomeno *català*.

## Disseny i característiques

- Un peu de pàgina amb enllaços útils.
- Un botó per canviar entre el mode clar i fosc.
- `site.description` a *theme.lua* per a una breu descripció del blog.
- `site.email` a *theme.lua* per afegir el teu email. Aquest ha d'estar al revés per ofuscar-ho.
-   Una pàgina d'error 404 ([https://avilagrijalva.github.io/404.html](https://avilagrijalva.github.io/404.html))
-   Esborranys o fitxers Markdown que no vull que apareguin a la llista d'índex, però que vull que es generin igualment per poder-hi accedir mitjançant un enllaç directe. Això s'aconsegueix amb `^[^_].*%.html$`, la qual cosa significa que tots els fitxers Markdown que comencin amb un subratllat es tractaran d'aquesta manera.
- Obfuscament del correu electrònic mitjançat CSS `unicode-bidi: bidi-override; direction: rtl`.
- Seguiment RSS localitzat a [https://avilagrijalva.github.io/feed.xml](https://avilagrijalva.github.io/feed.xml).
- Se li ha afegit l'etiqueta **update** al Markdown que es veu reflectit a:
  - *theme.lua* amb `<div class="date-update"><%= item.update %></div>`.
  - *post.lua* amb `<div class="date-update"><%= update %></div>`.
- Se li ha afegit l'etiqueta **keyword** a *theme.lua* amb `<div class="keyword">
    <% if item.keywords then -%>
        <%- keywordList(pathToRoot, item.keywords) %>
    <% end -%></div><% end -%>
`
- Se li ha afegit l'etiqueta **description** a *theme.lua* amb `<div class="description"><%= item.description %></div>`.
- Se li ha afegit l'etiqueta **readingTime** a *theme.lua* amb `<%= item.readingTime %>`.

## Contingut i llicències

Aquest projecte opera sota una **doble llicència** per separar el codi del contingut editorial:

1. **Codi del Tema**

Tot el codi font desenvolupat per a aquest tema està llicenciat sota la **GNU General Public License v3.0 (GPLv3)**.
Això garanteix que el programari romangui lliure i obert per a tothom.
Pots consultar el text complet a l'arxiu [LICENSE](https://github.com/avilagrijalva/avilagrijalva.github.io/blob/main/LICENSE).

2. **Contingut (Articles i Textos)**

Tret que s'indiqui el contrari, el contingut dels articles, les entrades del blog i la documentació està subjecte a la llicència **Creative Commons Reconeixement-CompartirIgual 4.0 Internacional (CC BY-SA 4.0)**.
Això significa que ets lliure de compartir i adaptar el contingut, sempre que donis el crèdit adequat i distribueixis les teves contribucions sota la mateixa llicència.

## Analítiques i privacitat

- **Analítiques**: Aquest lloc no posseeix ni utilitza serveis d'analítica.
- **Galetes**: Aquest lloc no utilitza galetes.
- **Anuncis**: Aquest lloc és completament lliure d'anuncis.
- **Conservació de dades**: Nosaltres no guardem cap dada de la teva visita.

Els articles d'aquest lloc poden incloure contingut incrustat (per exemple, vídeos, imatges, articles, etc.). El contingut incrustat d'altres webs es comporta exactament de la mateixa manera que si el visitant hagués visitat l'altra web.

Aquests webs poden recopilar dades sobre tu, utilitzar galetes, incrustar un seguiment addicional de tercers, i supervisar la teva interacció amb aquest contingut incrustat, inclòs el seguiment de la teva interacció amb el contingut incrustat si tens un compte i estàs connectat a aquest web.