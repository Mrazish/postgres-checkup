# {{ .checkId }} Data Checksums and wal_log_hints

## Observations ##
Data collected: {{ DtFormat .timestamptz }}
{{ if .hosts.master }}
{{ if (index .results .hosts.master) }}
{{ if (index (index .results .hosts.master) "data") }}
### Master (`{{ .hosts.master }}`) ###
| Setting | Value |
|---------|-------|
| data_checksums | {{ (index (index .results .hosts.master) "data").data_checksums }} |
| wal_log_hints | {{ (index (index .results .hosts.master) "data").wal_log_hints }} |
{{ end }}{{ end }}{{ end }}
{{ if gt (len .hosts.replicas) 0 }}
### Replica servers ###
{{ range $skey, $host := .hosts.replicas }}
{{- if (index $.results $host) }}
{{- if (index (index $.results $host) "data") }}
#### Replica (`{{ $host }}`) ####
| Setting | Value |
|---------|-------|
| data_checksums | {{ (index (index $.results $host) "data").data_checksums }} |
| wal_log_hints | {{ (index (index $.results $host) "data").wal_log_hints }} |
{{ end }}{{ end }}{{ end }}
{{ end }}

## Conclusions ##


## Recommendations ##

