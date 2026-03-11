shared = require("themes.shared")

-- Helpers
local htmlDateTemplate = etlua.compile([[<time datetime="<%= short %>"><%= long %></time>]])
local months = { "Gener", "Febrer", "Març", "Abril", "Maig", "Juny", "Juliol", "Agost", "Setembre", "Octubre", "Novembre", "Desembre" }
function htmlifyDateShort(date)
	local year, month, day = string.match(date, "^(%d%d%d%d)-(%d%d)-(%d%d)")
	return htmlDateTemplate({ short = date, long = months[string.toNumber(month)] .. " " .. day })
end

function htmlifyDate(date)
	local year, month, day = string.match(date, "^(%d%d%d%d)-(%d%d)-(%d%d)")
	local longDate = string.toNumber(day) .. " de " .. string.lower(months[string.toNumber(month)]) .. " de " .. year
	return htmlDateTemplate({ short = date, long = longDate })
end

local keywordListTemplate = etlua.compile([[<%
for i, k in ipairs(keywords) do -%><% if i > 1 then %> | <% end %><a href="<%= pathToRoot %>topics/<%= k %>.html">#<%= k %></a>
<% end -%>]])
function keywordList(pathToRoot, keywords)
	return keywordListTemplate({ pathToRoot = pathToRoot, keywords = keywords })
end

local postListTemplate = etlua.compile([[
<% local lastYear = nil -%>
<ul class="post-list-container">
<% for i, item in ipairs(table.sortBy(items, "date", true)) do
   local year = string.match(item.date, "^(%d%d%d%d)")
   if lastYear ~= year then -%>
     <li class="year-header"><%= year %></li>
<% lastYear = year end -%>
    <li class="post-row">
        <div class="post-entry-header">
            <span class="post-entry-title">
                <a href="<%= pathToRoot %><%= item.path %>"><%= item.title %></a>
            </span>
            
            <div class="post-entry-right">
                <span class="post-date"><%- htmlifyDateShort(item.date) %></span>
                <% if item.keywords then -%>
                <span class="post-entry-keywords">
                    <%- keywordList(pathToRoot, item.keywords) %>
                </span>
                <% end -%>
                <% if item.readingTime then -%>
                <span class="post-entry-reading-time">
                    · <%= item.readingTime %>
                </span>
                <% end -%>
            </div>
        </div>
        
        <% if item.description then -%>
            <p class="post-entry-description">
                <%= item.description %>
            </p>
        <% end -%>
        
        <% if item.update then -%>
        <div class="post-entry-meta">
            <span><%= item.update %></span>
        </div>
        <% end -%>
    </li>
<% end -%>
</ul>
]])
function postList(self)
	return postListTemplate({ pathToRoot = self.pathToRoot, items = self.items })
end

-- Hard-code syntax highlighting as normal HTML markup to support non-CSS browsers (e.g. terminal browsers)
local tagToElement = {}
for e, list in pairs({
	i = {"comment", "preprocessor", "bold", "italic", "number", "underline", "string"},
	b = {"tag", "function", "heading", "label", "annotation", "class", "type", "keyword"},
	u = {"link", "list", "error", "regex"},
}) do
	for _, t in ipairs(list) do
		tagToElement[t] = e
	end
end

local function highlightSpan(verbatim, tag)
	local element = tagToElement[tag] or "span"
	return "<" .. element .. " class=\"hl-" .. tag .. "\">" .. verbatim .. "</" .. element .. ">"
end

-- ==========================================
-- NUEVA FUNCIÓN PARA NOTAS AL PIE
-- ==========================================
local function generateFootnotes(text)
    if not text then return "" end

    local footnotes = {}
    local order = {}
    local count = 0

    -- 1. Extraer las definiciones
    text = string.gsub(text, "%[%^([^%]]+)%]:%s*([^\n]+)", function(id, content)
        if not footnotes[id] then
            table.insert(order, id)
        end
        footnotes[id] = content
        return "" 
    end)

    -- 2. Reemplazar las referencias
    text = string.gsub(text, "%[%^([^%]]+)%]", function(id)
        if footnotes[id] then
            count = count + 1
            return string.format('<sup id="fnref:%s"><a href="#fn:%s" class="footnote-ref">%d</a></sup>', id, id, count)
        else
            return string.format('[^%s]', id)
        end
    end)

    -- 3. Inyectar la lista al final
    if #order > 0 then
        local html = { '\n<hr class="footnotes-sep">\n<section class="footnotes">\n<ol>' }
        for _, id in ipairs(order) do
            local content = footnotes[id]
            table.insert(html, string.format('<li id="fn:%s">%s <a href="#fnref:%s" class="footnote-backref" title="Tornar al text">↩</a></li>', id, content, id))
        end
        table.insert(html, '</ol>\n</section>')
        
        text = text .. table.concat(html, "\n")
    end

    return text
end
-- ==========================================

-- ==========================================
-- FUNCIÓN PARA TABLA DE CONTENIDOS (TOC) CON FLECHA DE RETORNO
-- ==========================================
local function generateTOC(text)
    if not text or not string.find(text, "%[TOC%]") then return text end

    local toc_items = {}
    local counter = 0

    text = "\n" .. text

    text = string.gsub(text, "\n(#+)%s+([^\n]+)", function(hashes, title)
        counter = counter + 1
        local level = #hashes
        
        local slug = string.lower(title)
        slug = string.gsub(slug, "[%p]", "") 
        slug = string.gsub(slug, "%s+", "-") 
        if slug == "" then slug = "seccion-" .. counter end

        table.insert(toc_items, string.format('<li class="toc-h%d"><a href="#%s">%s</a></li>', level, slug, title))

        return string.format('\n<a id="%s"></a>\n%s %s <a href="#toc" class="toc-return" title="Tornar a l\'índex">↩</a>', slug, hashes, title)
    end)

    text = string.sub(text, 2)

    if counter == 0 then
        return string.gsub(text, "%[TOC%]", "")
    end

    local toc_html = {
        '<div id="toc" class="toc-container">',
        '  <p class="toc-title">Continguts</p>',
        '  <ul>',
        table.concat(toc_items, "\n"),
        '  </ul>',
        '</div>'
    }

    text = string.gsub(text, "%[TOC%]", table.concat(toc_html, "\n"))

    return text
end
-- ==========================================

-- Site metadata
local site = {
	title = "alunya.cat/Alan",
	url = "https://alunya.cat/alan/",
    description = "Breus apunts sobre temes diversos, coses quotidianes que aprenc, coses que sé però sovint oblido, i qualsevol altra cosa que em vingui de gust escriure mentre aprenc en públic. No sempre és definitiu ni nou, però espero que sigui útil o, si més no, interessant.",
    email = "tac.aynula@tac",
    author = "Alan",
}

local siteOverrides = fs.tryLoadFile("site.lua")
if siteOverrides then
	table.merge(siteOverrides(), site)
end

local source = args[3] or "content"
local destination = args[4] or "./"

-- Build pipeline
return {
    readFromSource(source),
    injectFiles({ 
        ["style.css"] = fs.readThemeFile("style.css"), 
        ["_404.html"] = "",
    }),
    -- ==========================================
    deriveMetadata({
        content = function (item)
            if item.content and type(item.content) == "string" then
                local processed_text = item.content
                local protected_blocks = {}
                
                -- Función auxiliar para guardar el texto original y dejar una marca
                local function protect(match)
                    table.insert(protected_blocks, match)
                    return "___PROTECTED_" .. #protected_blocks .. "___"
                end

                -- 1. Proteger bloques de código multilínea (```...```)
                processed_text = string.gsub(processed_text, "(```.-```)", protect)
                
                -- 2. Proteger código en línea (`...`)
                processed_text = string.gsub(processed_text, "(`[^`]+`)", protect)

                -- 3. Proteger URLs (empiezan con http:// o https:// y siguen sin espacios)
                -- Esto protege enlaces sueltos y las URLs dentro de los paréntesis en Markdown [texto](url)
                processed_text = string.gsub(processed_text, "(https?://%S+)", protect)

                -- 4. Proteger etiquetas HTML (por si tienes atributos como <a href="...[TOC]...">)
                processed_text = string.gsub(processed_text, "(<[^>]+>)", protect)

                -- ==========================================
                -- Ejecutamos las modificaciones seguras
                -- ==========================================
                processed_text = generateFootnotes(processed_text)
                processed_text = generateTOC(processed_text)

                -- ==========================================
                -- Restauramos el texto original
                -- ==========================================
                -- Usamos un bucle while por si alguna marca quedó anidada o junta
                local count = 1
                while count > 0 do
                    processed_text, count = string.gsub(processed_text, "___PROTECTED_(%d+)___", function(index)
                        return protected_blocks[tonumber(index)]
                    end)
                end

                return processed_text
            end
            return item.content
        end
    }),
    -- ==========================================
    processMarkdown(),
    omitWhen(function (item) return item.draft or item.path == "site.lua" end),
    highlightSyntax(highlightSpan),
    -- readingTime
    deriveMetadata({
        readingTime = function (item)
            if not item.content then return "1 min" end
            local text = string.gsub(item.content, "<.->", " ")
            local _, words = string.gsub(text, "%S+", "")
            local minutes = math.ceil(words / 200)
            if minutes < 1 then minutes = 1 end
            return minutes .. " min"
        end
    }),

    -- 404.etlua
    injectMetadata({
        title = "Pàgina no encontrada", 
        pathToRoot = site.url,
        date = "1970-01-01",
    }, "^_404.html$"),

    -- Filter 
    aggregate("feed.xml", "^[^_].*%.html$"),
    aggregate("index.html", "^[^_].*%.html$"),

    -- Keywords
    createIndexes(function (keyword) return "topics/" .. keyword .. ".html" end, "keywords", "^[^_].*%.html$"),
    deriveMetadata({ title = function (item) return item.key end }, "^topics/.-%.html$"),
    injectMetadata({ site = site }),
    
    -- Templates
    applyTemplates({
        
        { "%.html$", fs.readThemeFile("post.etlua") },
        { "^topics/.-%.html$", fs.readThemeFile("index.etlua") },
        { "^feed.xml$", fs.readThemeFile("feed.etlua") },
        { "^index.html$", fs.readThemeFile("blog.etlua") },
        { "^_404.html$", fs.readThemeFile("404.etlua") },
    }),
    applyTemplates({ { "%.html$", fs.readThemeFile("outer.etlua") } }),

    -- Using an underscore for _404.html keeps it out of article lists. The file is built using its own template and then renamed after generation.
    omitWhen(function(item)
        if item.path == "_404.html" then
            item.path = "404.html"
        end
        return false
    end),

    checkLinks(),
    writeToDestination(destination),
}