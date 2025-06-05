# {{ .checkId }} Connection Pooling

## Observations ##
Data collected: {{ DtFormat .timestamptz }}
{{ if .hosts.master }}
{{ if (index .results .hosts.master) }}
{{ if (index (index .results .hosts.master) "data") }}
### Master (`{{ .hosts.master }}`) ###
| Parameter | Value |
|-----------|-------|
| pgbouncer_installed | {{ (index (index .results .hosts.master) "data").pgbouncer_installed }} |
| pgbouncer_running | {{ (index (index .results .hosts.master) "data").pgbouncer_running }} |
{{ end }}{{ end }}{{ end }}
{{ if gt (len .hosts.replicas) 0 }}
### Replica servers ###
{{ range $skey, $host := .hosts.replicas }}
{{- if (index $.results $host) }}
{{- if (index (index $.results $host) "data") }}
#### Replica (`{{ $host }}`) ####
| Parameter | Value |
|-----------|-------|
| pgbouncer_installed | {{ (index (index $.results $host) "data").pgbouncer_installed }} |
| pgbouncer_running | {{ (index (index $.results $host) "data").pgbouncer_running }} |
{{ end }}{{ end }}{{ end }}
{{ end }}

## Conclusions ##


## Recommendations ##

