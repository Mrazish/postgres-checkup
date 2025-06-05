# {{ .checkId }} Anti-crash Settings

## Observations ##
Data collected: {{ DtFormat .timestamptz }}
{{ if .hosts.master }}
{{ if (index .results .hosts.master) }}
{{ if (index (index .results .hosts.master) "data") }}
### Master (`{{ .hosts.master }}`) ###
| Setting | Value |
|---------|-------|
| fsync | {{ (index (index .results .hosts.master) "data").fsync }} |
| full_page_writes | {{ (index (index .results .hosts.master) "data").full_page_writes }} |
| synchronous_commit | {{ (index (index .results .hosts.master) "data").synchronous_commit }} |
{{ end }}{{ end }}{{ end }}
{{ if gt (len .hosts.replicas) 0 }}
### Replica servers ###
{{ range $skey, $host := .hosts.replicas }}
{{- if (index $.results $host) }}
{{- if (index (index $.results $host) "data") }}
#### Replica (`{{ $host }}`) ####
| Setting | Value |
|---------|-------|
| fsync | {{ (index (index $.results $host) "data").fsync }} |
| full_page_writes | {{ (index (index $.results $host) "data").full_page_writes }} |
| synchronous_commit | {{ (index (index $.results $host) "data").synchronous_commit }} |
{{ end }}{{ end }}{{ end }}
{{ end }}

## Conclusions ##


## Recommendations ##

