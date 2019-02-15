{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 64,
  "links": [],
  "panels": [
    {
      "alert": {
        "conditions": [
          {
            "evaluator": {
              "params": [
                0.95
              ],
              "type": "lt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A",
                "5m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "min"
            },
            "type": "query"
          },
          {
            "evaluator": {
              "params": [
                0.95
              ],
              "type": "lt"
            },
            "operator": {
              "type": "or"
            },
            "query": {
              "params": [
                "B",
                "5m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "min"
            },
            "type": "query"
          },
          {
            "evaluator": {
              "params": [
                0.95
              ],
              "type": "lt"
            },
            "operator": {
              "type": "or"
            },
            "query": {
              "params": [
                "C",
                "5m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "min"
            },
            "type": "query"
          },
          {
            "evaluator": {
              "params": [
                0.95
              ],
              "type": "lt"
            },
            "operator": {
              "type": "or"
            },
            "query": {
              "params": [
                "D",
                "5m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "min"
            },
            "type": "query"
          }
        ],
        "executionErrorState": "alerting",
        "for": "5m",
        "frequency": "1m",
        "handler": 1,
        "name": "Hub SAML Proxy Endpoint Reliability alert",
        "noDataState": "no_data",
        "notifications": []
      },
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${source}",
      "fill": 1,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "uk_gov_ida_hub_samlproxy_resources_SamlMessageReceiverApi_handleRequestPost_2xx_responses_total / uk_gov_ida_hub_samlproxy_resources_SamlMessageReceiverApi_handleRequestPost_count",
          "format": "time_series",
          "intervalFactor": 1,
          "refId": "A"
        },
        {
          "expr": "uk_gov_ida_hub_samlproxy_resources_SamlMessageReceiverApi_handleResponsePost_2xx_responses_total / uk_gov_ida_hub_samlproxy_resources_SamlMessageReceiverApi_handleResponsePost_count",
          "format": "time_series",
          "intervalFactor": 1,
          "refId": "B"
        },
        {
          "expr": "uk_gov_ida_hub_samlproxy_resources_SamlMessageSenderApi_sendJsonAuthnRequestFromHub_2xx_responses_total / uk_gov_ida_hub_samlproxy_resources_SamlMessageSenderApi_sendJsonAuthnRequestFromHub_count",
          "format": "time_series",
          "intervalFactor": 1,
          "refId": "C"
        },
        {
          "expr": "uk_gov_ida_hub_samlproxy_resources_SamlMessageSenderApi_sendJsonAuthnResponseFromHub_2xx_responses_total / uk_gov_ida_hub_samlproxy_resources_SamlMessageSenderApi_sendJsonAuthnResponseFromHub_count",
          "format": "time_series",
          "intervalFactor": 1,
          "refId": "D"
        }
      ],
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "lt",
          "value": 0.95
        }
      ],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Hub SAML Proxy Endpoint Reliability",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "percentunit",
          "label": null,
          "logBase": 1,
          "max": "1",
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "schemaVersion": 16,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "[${deployment}] Page Type Alerts",
  "uid": "UySkbuuiz",
  "version": 2
}
