# frozen_string_literal: true

module Satchel
  # Raises the letters of ordinal day numbers, wherever they appear in a
  # page's text: "28th October" becomes 28<sup class="ordinal">th</sup>
  # October. It covers dates written in a post's prose as well as the ones
  # the layouts render with date_to_long_string.
  #
  # Only text between tags is changed, never tags or their attributes, and
  # nothing inside elements whose text must stay exactly as written.
  module OrdinalSuperscript
    ORDINAL = /\b(\d{1,2})(st|nd|rd|th)\b/
    TAG = /(<[^>]*>)/
    VERBATIM = %w[code pre script style textarea title].freeze
    OPENING = %r{\A<(#{VERBATIM.join("|")})[\s>]}i
    CLOSING = %r{\A</(#{VERBATIM.join("|")})\s*>}i

    def self.apply(html)
      depth = 0
      html.split(TAG).map do |part|
        if part.start_with?("<")
          depth += 1 if part.match?(OPENING)
          depth -= 1 if part.match?(CLOSING) && depth.positive?
          part
        elsif depth.zero?
          part.gsub(ORDINAL, '\1<sup class="ordinal">\2</sup>')
        else
          part
        end
      end.join
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  item.output = Satchel::OrdinalSuperscript.apply(item.output) if item.output_ext == ".html"
end
