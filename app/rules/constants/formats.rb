module Constants::Formats
  FORMATS = {
    AU: {
      au_abn: /^\d{11}$/,
      au_acn: /^\d{9}$/
    },
    CA: { ca_gst: /^\d{9}RT0001$/ },
    IN: { in_gst: /^\d{2}[A-Z0-9]{10}[A-Z]\d[A-Z]\d$/ }
  }.freeze

  GROUPINGS = {
    au_abn: /(\d{2})(\d{3})(\d{3})(\d{3})/,
    au_acn: /(\d{3})(\d{3})(\d{3})/
  }.freeze
end
