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

local postListTemplate = etlua.compile([[
<% local lastYear = nil -%>
<div class="post-list-container">
<% for i, item in ipairs(table.sortBy(items, "date", true)) do
   local year = string.match(item.date, "^(%d%d%d%d)")
   if lastYear ~= year then -%>
     <h2 class="year-header"><span class="icon">&sect;</span> <%= year %></h2>
<%
	 lastYear = year
   end
-%>
<article>
    <h3 class="post-entry-title">
        <a href="<%= pathToRoot %><%= item.path %>"><span class="icon-title">&#8250;</span><%= item.title %></a>
    </h3>
    <% if item.description then -%>
     <p class="post-entry-description"><%= item.description %></p>
    <% end -%>
    <div class="post-entry-meta">
        <%- htmlifyDate(item.date) %>
        <% if item.readingTime then %> 
        · <%= item.readingTime %> <% end %>
        <% if item.keywords then -%>
        · <%- keywordList(pathToRoot, item.keywords) %>
        <% if item.update then -%>
        · <span><%= item.update %></span>
        <% end -%>
    </div>
    <% end -%>
</article>
<% end -%>
</div>
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
    email = "moc.liamg@avlajirgalivaloiro",
    author = "Oriol Àvila Grijalva",
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