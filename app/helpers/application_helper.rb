module ApplicationHelper
  TONE_CLASS = {
    "success" => "tone-success",
    "warning" => "tone-warning",
    "danger" => "tone-danger",
    "info" => "tone-info",
    "neutral" => "tone-neutral",
    "accent" => "tone-accent"
  }.freeze

  EVIDENCE_STATUS = {
    "accepted" => ["Accepted", "success"],
    "needs_review" => ["Needs review", "warning"],
    "needs_mapping" => ["Needs mapping", "warning"],
    "projected" => ["Projected", "info"],
    "rejected" => ["Rejected", "danger"],
    "schema_error" => ["Schema error", "danger"],
    "pending" => ["Pending", "neutral"]
  }.freeze

  def page_title(title)
    content_for(:title, title)
  end

  def nav_active?(path, exact: false)
    current = request.path.chomp("/")
    target = path.chomp("/")
    exact ? current == target : current == target || current.start_with?("#{target}/")
  end

  def nav_link(path, label, badge: nil, exact: false, icon: nil)
    classes = ["nav-link"]
    classes << "active" if nav_active?(path, exact: exact)
    link_to path, class: classes.join(" ") do
      safe_join([
        (content_tag(:span, icon, class: "nav-icon", aria: { hidden: true }) if icon),
        content_tag(:span, label, class: "truncate"),
        (content_tag(:span, badge, class: "nav-badge") if badge)
      ].compact)
    end
  end

  def tab_link(path, label, exact: false)
    classes = ["tab-link"]
    classes << "active" if nav_active?(path, exact: exact)
    link_to label, path, class: classes.join(" ")
  end

  def badge(label, tone: "neutral", dot: false, mono: false)
    classes = ["badge", TONE_CLASS.fetch(tone.to_s, "tone-neutral")]
    classes << "mono" if mono
    content_tag(:span, class: classes.join(" ")) do
      parts = []
      parts << content_tag(:span, "", class: "badge-dot") if dot
      parts << label.to_s
      safe_join(parts)
    end
  end

  def evidence_badge(status)
    label, tone = EVIDENCE_STATUS.fetch(status.to_s, [status.to_s.titleize, "neutral"])
    badge(label, tone: tone)
  end

  def severity_badge(severity)
    tone = { "high" => "danger", "medium" => "warning", "low" => "info" }.fetch(severity.to_s, "neutral")
    badge(severity.to_s.upcase, tone: tone, mono: true)
  end

  def status_tone(status)
    case status.to_i
    when 200..299 then "success"
    when 300..399 then "info"
    when 400..499 then "warning"
    else "danger"
    end
  end

  def format_utc(value)
    return "" unless value

    time = value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone) ? value : Time.zone.parse(value.to_s)
    time.utc.strftime("%d %b %Y %H:%M UTC")
  end

  def json_pretty(value)
    JSON.pretty_generate(value || {})
  end

  def panel(title = nil, class_name: nil, &block)
    content_tag(:section, class: ["panel", class_name].compact.join(" ")) do
      body = []
      body << content_tag(:div, title, class: "section-title") if title
      body << capture(&block)
      safe_join(body)
    end
  end

  def key_values(rows)
    content_tag(:dl, class: "kv") do
      safe_join(rows.map do |label, value, mono|
        content_tag(:div) do
          safe_join([
            content_tag(:dt, label),
            content_tag(:dd, value, class: mono ? "mono" : nil)
          ])
        end
      end)
    end
  end

  def current_project_path(project, suffix = nil)
    base = project_path(project.slug)
    suffix.present? ? "#{base}/#{suffix}" : base
  end
end
