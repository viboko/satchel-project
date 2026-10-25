# frozen_string_literal: true

require "cgi"
require "rouge"

module Satchel
  # Renders an excerpt of a file from a GitHub repository, highlighted, with
  # the file's own line numbers down the side and a link to those lines on
  # GitHub underneath:
  #
  #   {% code_snippet lang="ts" path="src/lib/solid-save.ts" start=145 %}
  #   ...the lines, exactly as they are in the file...
  #   {% endcode_snippet %}
  #
  # The repository and commit come from the page's `code_source` front matter
  # (`repo` and `ref`), or from `repo=` and `ref=` on the tag. Pin `ref` to a
  # commit, not a branch, so the line numbers and the link can't drift from
  # the file they quote. Common leading indentation is removed, so an
  # excerpt from inside a function needn't start far to the right.
  #
  # It's a raw block, like `{% raw %}`, so the code is never parsed as Liquid.
  class CodeSnippetBlock < Liquid::Raw
    ATTRIBUTE = /(\w+)=(?:"([^"]*)"|(\S+))/

    def initialize(tag_name, markup, parse_context)
      super
      @attributes = markup.scan(ATTRIBUTE).to_h { |name, quoted, bare| [name, quoted || bare] }
    end

    def render(context)
      source = context.registers[:page]["code_source"] || {}
      repo = @attributes["repo"] || source["repo"]
      ref = @attributes["ref"] || source["ref"]
      path = @attributes.fetch("path") { raise ArgumentError, "code_snippet: no path=" }
      start = Integer(@attributes.fetch("start") { raise ArgumentError, "code_snippet: no start= for #{path}" })
      raise ArgumentError, "code_snippet: no repo or ref for #{path}" unless repo && ref

      lines = highlighted_lines(dedent(@body), @attributes.fetch("lang", "plaintext"))
      finish = start + lines.length - 1
      url = "https://github.com/#{repo}/blob/#{ref}/#{path}#L#{start}#{"-L#{finish}" if finish > start}"
      range = finish > start ? "Lines #{start}–#{finish}" : "Line #{start}"

      code = lines.each_with_index.map do |html, index|
        %(<span class="code-snippet__line" data-line="#{start + index}">#{html}\n</span>)
      end.join

      # nomarkdown stops kramdown from touching the generated HTML.
      <<~HTML
        {::nomarkdown}
        <figure class="code-snippet">
        <pre class="highlight code-snippet__code"><code>#{code}</code></pre>
        <figcaption class="code-snippet__source">
        <span class="code-snippet__path">#{CGI.escapeHTML(path)}</span>
        <a href="#{CGI.escapeHTML(url)}" target="_blank" rel="noopener">#{range} on GitHub</a>
        </figcaption>
        </figure>
        {:/nomarkdown}
      HTML
    end

    private

    # Liquid::Raw rejects any markup after its tag name; this tag needs some.
    def ensure_valid_markup(_tag_name, _markup, _parse_context); end

    def dedent(body)
      lines = body.sub(/\A\s*\n/, "").rstrip.split("\n")
      indent = lines.reject { |line| line.strip.empty? }.map { |line| line[/\A */].length }.min || 0
      lines.map { |line| line[indent..] || "" }
    end

    # Highlights the lines as one piece, so tokens that span lines (comments,
    # template strings) are lexed correctly, then splits the tokens back into
    # lines so each line can be wrapped in its own element.
    def highlighted_lines(lines, lang)
      lexer = Rouge::Lexer.find(lang) or raise ArgumentError, "code_snippet: no Rouge lexer for #{lang}"
      formatter = Rouge::Formatters::HTML.new
      output = [+""]
      lexer.lex(lines.join("\n")).each do |token, value|
        value.split("\n", -1).each_with_index do |part, index|
          output << +"" if index.positive?
          output.last << formatter.span(token, part) unless part.empty?
        end
      end
      output.first(lines.length)
    end
  end
end

Liquid::Template.register_tag("code_snippet", Satchel::CodeSnippetBlock)
