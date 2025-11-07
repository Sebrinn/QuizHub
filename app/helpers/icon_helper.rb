module IconHelper
  def icon(name, size: "md", css_class: "")
    size_class = case size
    when "sm" then "icon-sm"
    when "lg" then "icon-lg"
    when "xl" then "icon-xl"
    else "icon"
    end

    content_tag(:svg, class: "#{size_class} #{css_class}", aria_hidden: true) do
      content_tag(:use, "", "xlink:href": "#icon-#{name}")
    end
  end

  def icon_with_text(icon_name, text, size: "md")
    content_tag(:span, class: "icon-text") do
      safe_join([ icon(icon_name, size: size), content_tag(:span, text) ])
    end
  end
end
