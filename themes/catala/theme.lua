shared = require("themes.shared")

-- Helpers
local htmlDateTemplate = etlua.compile([[<time datetime="<%= short %>"><%= long %></time>]])
local months = { "Gener", "Febrer", "Març", "Abril", "Maig", "Juny", "Juliol", "Agost", "Setembre", "Octubre", "Novembre", "Desembre" }
function htmlifyDateShort(date)
	local year, month, day = string.match(date, "^(%d%d%d%d)-(%d%d)-(%d%d)")
	return htmlDateTemplate({ short = date, long = months[string.toNumber(month)] .. " " .. day })
end

function htmlifyDate(date)
	return htmlDateTemplate({ short = date, long = shared.formatDate(date) })
end

local keywordListTemplate = etlua.compile([[<%
for i, k in ipairs(keywords) do -%><% if i > 1 then %> | <% end %><a href="<%= pathToRoot %>topics/<%= k %>.html">#<%= k %></a>
<% end -%>]])
function keywordList(pathToRoot, keywords)
	return keywordListTemplate({ pathToRoot = pathToRoot, keywords = keywords })
end

local postListTemplate = etlua.compile([[<% local lastYear = nil -%>
<% for i, item in ipairs(table.sortBy(items, "date", true)) do
   local year = string.match(item.date, "^(%d%d%d%d)")
   if lastYear ~= year then
     if lastYear ~= nil then -%>
</ul>
<% end -%>
<h2><%= year %></h2>
<ul class="posts">
<%
	 lastYear = year
   end
-%>
<li class="item-flex"><a href="<%= pathToRoot %><%= item.path %>"><%= item.title %></a>
<div class="description"><%= item.description %></div>
<span><%- htmlifyDateShort(item.date) %></span></li>
<div class="date-update"><%= item.update %></div>
<div class="keyword">
    <% if item.keywords then -%>
        <%- keywordList(pathToRoot, item.keywords) %>
    <% end -%></div>
<% end -%>
<% if #items > 0 then -%>
</ul>
<% end -%>
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

-- Site metadata
local site = {
	title = "Oriol Àvila Grijalva",
	url = "https://avilagrijalva.github.io/",
    description = "Breus apunts sobre temes diversos, coses quotidianes que aprenc, coses que sé però sovint oblido, i qualsevol altra cosa que em vingui de gust escriure mentre aprenc en públic. No sempre és definitiu ni nou, però espero que sigui útil o, si més no, interessant.",
}

local siteOverrides = fs.tryLoadFile("site.lua")
if siteOverrides then
	table.merge(siteOverrides(), site)
end

local source = args[3] or "content"
local destination = args[4] or "out"

-- Build pipeline
return {
    readFromSource(source),
    injectFiles({ 
        ["style.css"] = fs.readThemeFile("style.css"), 
        ["_404.html"] = "",
    }),

    processMarkdown(),
    omitWhen(function (item) return item.path == "site.lua" end),
    highlightSyntax(highlightSpan),

    -- 404.etlua
    injectMetadata({
        title = "Página no encontrada", 
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
        { "^feed.xml$", fs.readThemeFile("../shared/feed.etlua") },
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