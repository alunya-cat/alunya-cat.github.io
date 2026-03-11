-- Load shared theme functions and utilities
shared = require("themes.shared")

-- ==========================================
-- DATE FORMATTING HELPERS
-- ==========================================

-- HTML template for standardizing date output
local htmlDateTemplate = etlua.compile([[<time datetime="<%= short %>"><%= long %></time>]])

-- Array of month names in Catalan
local months = { "Gener", "Febrer", "Març", "Abril", "Maig", "Juny", "Juliol", "Agost", "Setembre", "Octubre", "Novembre", "Desembre" }

-- Function to generate a short date format (e.g., "Març 11")
function htmlifyDateShort(date)
	local year, month, day = string.match(date, "^(%d%d%d%d)-(%d%d)-(%d%d)")
	return htmlDateTemplate({ short = date, long = months[string.toNumber(month)] .. " " .. day })
end

-- Function to generate a long, fully localized date format (e.g., "11 de març de 2026")
function htmlifyDate(date)
	local year, month, day = string.match(date, "^(%d%d%d%d)-(%d%d)-(%d%d)")
	local longDate = string.toNumber(day) .. " de " .. string.lower(months[string.toNumber(month)]) .. " de " .. year
	return htmlDateTemplate({ short = date, long = longDate })
end

-- ==========================================
-- KEYWORD / TAGS HELPERS
-- ==========================================

-- Template to generate the list of clickable tags/keywords with a separator (|)
local keywordListTemplate = etlua.compile([[<%
for i, k in ipairs(keywords) do -%><% if i > 1 then %> | <% end %><a href="<%= pathToRoot %>topics/<%= k %>.html">#<%= k %></a>
<% end -%>]])

-- Function to render the keyword list template
function keywordList(pathToRoot, keywords)
	return keywordListTemplate({ pathToRoot = pathToRoot, keywords = keywords })
end

-- ==========================================
-- POST LIST TEMPLATE (INDEX / BLOG)
-- ==========================================

-- Template to render the list of posts grouped by year. 
-- It displays the title, date, reading time, tags, description, and update dates.
local postListTemplate = etlua.compile([[
<% local lastYear = nil -%>
<ul class="post-list-container">
<% for i, item in ipairs(table.sortBy(items, "date", true)) do
   local year = string.match(item.date, "^(%d%d%d%d)")
   -- Print the year header only when it changes
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

-- Function to execute the post list template
function postList(self)
	return postListTemplate({ pathToRoot = self.pathToRoot, items = self.items })
end

-- ==========================================
-- SYNTAX HIGHLIGHTING (TERMINAL/RAW HTML FALLBACK)
-- ==========================================

-- Hard-code syntax highlighting as normal HTML markup to support non-CSS browsers (e.g., terminal browsers)
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

-- Function to map parsed code tokens to their corresponding fallback HTML elements
local function highlightSpan(verbatim, tag)
	local element = tagToElement[tag] or "span"
	return "<" .. element .. " class=\"hl-" .. tag .. "\">" .. verbatim .. "</" .. element .. ">"
end

-- ==========================================
-- FOOTNOTES GENERATOR
-- ==========================================
-- Parses markdown-style footnotes [^1] and creates hyperlinked references 
-- along with an ordered list of definitions at the bottom of the content.
local function generateFootnotes(text)
    if not text then return "" end

    local footnotes = {}
    local order = {}
    local count = 0

    -- 1. Extract footnote definitions (e.g., [^1]: This is the text)
    text = string.gsub(text, "%[%^([^%]]+)%]:%s*([^\n]+)", function(id, content)
        if not footnotes[id] then
            table.insert(order, id)
        end
        footnotes[id] = content
        return "" 
    end)

    -- 2. Replace footnote references in text (e.g., [^1]) with superscript HTML links
    text = string.gsub(text, "%[%^([^%]]+)%]", function(id)
        if footnotes[id] then
            count = count + 1
            return string.format('<sup id="fnref:%s"><a href="#fn:%s" class="footnote-ref">%d</a></sup>', id, id, count)
        else
            -- If footnote definition is missing, leave the raw text
            return string.format('[^%s]', id)
        end
    end)

    -- 3. Inject the compiled footnote list at the bottom of the text
    if #order > 0 then
        local html = { '\n<hr class="footnotes-sep">\n<section class="footnotes">\n<ol>' }
        for _, id in ipairs(order) do
            local content = footnotes[id]
            -- Adds a return arrow link to go back to the exact reference in the text
            table.insert(html, string.format('<li id="fn:%s">%s <a href="#fnref:%s" class="footnote-backref" title="Tornar al text">↩</a></li>', id, content, id))
        end
        table.insert(html, '</ol>\n</section>')
        
        text = text .. table.concat(html, "\n")
    end

    return text
end

-- ==========================================
-- TABLE OF CONTENTS (TOC) GENERATOR
-- ==========================================
-- Scans for headers (#) and generates a TOC block where the [TOC] tag is placed.
-- Also appends a return arrow link next to each header in the document.
local function generateTOC(text)
    -- Exit early if the [TOC] marker is not present
    if not text or not string.find(text, "%[TOC%]") then return text end

    local toc_items = {}
    local counter = 0

    text = "\n" .. text

    -- Find markdown headers and create anchors and TOC items
    text = string.gsub(text, "\n(#+)%s+([^\n]+)", function(hashes, title)
        counter = counter + 1
        local level = #hashes
        
        -- Generate a URL-friendly slug from the title
        local slug = string.lower(title)
        slug = string.gsub(slug, "[%p]", "") 
        slug = string.gsub(slug, "%s+", "-") 
        if slug == "" then slug = "seccion-" .. counter end

        -- Add the item to the TOC list
        table.insert(toc_items, string.format('<li class="toc-h%d"><a href="#%s">%s</a></li>', level, slug, title))

        -- Reconstruct the header with an invisible anchor and a return arrow link
        return string.format('\n<a id="%s"></a>\n%s %s <a href="#toc" class="toc-return" title="Tornar a l\'índex">↩</a>', slug, hashes, title)
    end)

    text = string.sub(text, 2)

    -- If no headers were found, just remove the [TOC] tag
    if counter == 0 then
        return string.gsub(text, "%[TOC%]", "")
    end

    -- Construct the final HTML block for the TOC
    local toc_html = {
        '<div id="toc" class="toc-container">',
        '  <p class="toc-title">Continguts</p>',
        '  <ul>',
        table.concat(toc_items, "\n"),
        '  </ul>',
        '</div>'
    }

    -- Replace the [TOC] marker with the generated HTML
    text = string.gsub(text, "%[TOC%]", table.concat(toc_html, "\n"))

    return text
end


-- ==========================================
-- SITE CONFIGURATION
-- ==========================================
-- Default metadata used across the static site
local site = {
	title = "alunya.cat/Alan",
	url = "https://alunya.cat/alan/",
    description = "Breus apunts sobre temes diversos, coses quotidianes que aprenc, coses que sé però sovint oblido, i qualsevol altra cosa que em vingui de gust escriure mentre aprenc en públic. No sempre és definitiu ni nou, però espero que sigui útil o, si més no, interessant.",
    email = "tac.aynula@tac",
    author = "Alan",
}

-- Define input/output directories
local source = args[3] or "content"
local destination = args[4] or "./"

-- ==========================================
-- BUILD PIPELINE
-- ==========================================
-- The sequence of operations the Static Site Generator executes to build the site
return {
    readFromSource(source),
    
    -- Inject raw static files that don't need compilation
    injectFiles({ 
        ["style.css"] = fs.readThemeFile("style.css"), 
        ["_404.html"] = "",
    }),
    
    -- We process these custom tags before the main Markdown parser runs.
    -- To prevent accidentally modifying text that just looks like a tag 
    -- (e.g., a [TOC] written inside a code block or a URL parameter), 
    -- we use an "Extract & Restore" pattern:
    -- 1. Extract and hide sensitive blocks (code, URLs, HTML).
    -- 2. Generate the actual HTML for Footnotes and TOC.
    -- 3. Restore the hidden blocks to their original places.
    deriveMetadata({
        content = function (item)
            if item.content and type(item.content) == "string" then
                local processed_text = item.content
                local protected_blocks = {}
                
                -- Helper function to store original text and insert a placeholder
                local function protect(match)
                    table.insert(protected_blocks, match)
                    return "___PROTECTED_" .. #protected_blocks .. "___"
                end

                -- 1. Protect multiline code blocks (```...```)
                processed_text = string.gsub(processed_text, "(```.-```)", protect)
                
                -- 2. Protect inline code snippets (`...`)
                processed_text = string.gsub(processed_text, "(`[^`]+`)", protect)

                -- 3. Protect URLs (starting with http:// or https://) to avoid breaking links
                processed_text = string.gsub(processed_text, "(https?://%S+)", protect)

                -- 4. Protect raw HTML tags to preserve attributes like href, src, etc.
                processed_text = string.gsub(processed_text, "(<[^>]+>)", protect)

                -- Safely execute Footnotes and TOC logic over unprotected text
                processed_text = generateFootnotes(processed_text)
                processed_text = generateTOC(processed_text)

                -- Restore protected blocks to their original positions
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
    
    -- Convert markdown content into HTML
    processMarkdown(),
    
    -- Skip processing for draft articles
    omitWhen(function (item) return item.draft end),
    
    -- Apply syntax highlighting to code blocks
    highlightSyntax(highlightSpan),
    
    -- Calculate estimated reading time for each article
    deriveMetadata({
        readingTime = function (item)
            if not item.content then return "1 min" end
            -- Remove HTML tags temporarily to count words accurately
            local text = string.gsub(item.content, "<.->", " ")
            local _, words = string.gsub(text, "%S+", "")
            local minutes = math.ceil(words / 200) -- Assumes an average reading speed of 200 WPM
            if minutes < 1 then minutes = 1 end
            return minutes .. " min"
        end
    }),

    -- Configure metadata for the custom 404 page
    injectMetadata({
        title = "Pàgina no encontrada", 
        pathToRoot = site.url,
        date = "1970-01-01",
    }, "^_404.html$"),

    -- Generate aggregation pages (RSS feed and the main index)
    aggregate("feed.xml", "^[^_].*%.html$"),
    aggregate("index.html", "^[^_].*%.html$"),

    -- Generate tag/keyword index pages
    createIndexes(function (keyword) return "topics/" .. keyword .. ".html" end, "keywords", "^[^_].*%.html$"),
    deriveMetadata({ title = function (item) return item.key end }, "^topics/.-%.html$"),
    
    -- Inject global site metadata into every item
    injectMetadata({ site = site }),
    
    -- Bind specific `.etlua` templates to their respective output files
    applyTemplates({
        { "%.html$", fs.readThemeFile("post.etlua") },
        { "^topics/.-%.html$", fs.readThemeFile("index.etlua") },
        { "^feed.xml$", fs.readThemeFile("feed.etlua") },
        { "^index.html$", fs.readThemeFile("blog.etlua") },
        { "^_404.html$", fs.readThemeFile("404.etlua") },
    }),
    
    -- Wrap all HTML pages with the main outer layout template
    applyTemplates({ { "%.html$", fs.readThemeFile("outer.etlua") } }),

    -- Rename _404.html to 404.html. The underscore was used to prevent it from showing up in article lists.
    omitWhen(function(item)
        if item.path == "_404.html" then
            item.path = "404.html"
        end
        return false
    end),

    -- Final validation and output writing
    checkLinks(),
    writeToDestination(destination),
}