
# adds in a google logging metric from gateway that pareses out various fields
resource "google_logging_metric" "gatway" {
  name    = "gateway"
  project = var.project
  filter  = "textPayload=~\"reactor.netty.http.server.AccessLog\""

  label_extractors = {
    log_level     = "REGEXP_EXTRACT(textPayload, \"\\\\[.*\\\\] ([A-Z]+)\")"
    response_code = "REGEXP_EXTRACT(textPayload, \"\\\".*\\\" (\\\\d+)\")"
    response_time = "REGEXP_EXTRACT(textPayload, \"(\\\\d+) ms$\")"
    service_name  = "REGEXP_EXTRACT(textPayload, \"GET\\\\s\\\\/(.*?)\\\\/\")"
  }

  metric_descriptor {
    labels {
      key        = "service_name"
      value_type = "STRING"
    }

    labels {
      key        = "log_level"
      value_type = "STRING"
    }

    labels {
      key        = "response_code"
      value_type = "STRING"
    }

    labels {
      key        = "response_time"
      value_type = "INT64"
    }

    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }

}