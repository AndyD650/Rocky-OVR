module ApplicationHelper

  # flash_messages
  # use to display specified flash messages
  # defaults to standard set: [:success, :message, :warning]
  # example:
  #   <%= flash_messages %>
  # example with other keys:
  #   <%= flash_messages :notice, :violation %>
  # renders like:
  #  <ul class="flash">
  #   <li class="flash-success">Positive - successful action</li>
  #   <li class="flash-message">Neutral - reminders, status</li>
  #   <li class="flash-warning">Negative - error, unsuccessful action</li>
  #  </ul>
  def flash_messages(*keys)
    keys = [:success, :message, :warning] if keys.empty?
    messages = []
    keys.each do |key|
      messages << content_tag(:li, flash[key], :class => "flash-#{key}") if flash[key]
    end
    content_tag(:ul, messages.join("\n"), :class => "flash")
  end

  def clippy(text, bgcolor='#FFFFFF')
    html = <<-HTML
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              id="clippy" >
      <param name="movie" value="/flash/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=#{text}">
      <param name="bgcolor" value="#{bgcolor}">
      <embed src="/flash/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=#{text}"
             bgcolor="#{bgcolor}"
      />
      </object>
    HTML
  end
end
