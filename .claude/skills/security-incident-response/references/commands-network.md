# Network and exposure commands

This file covers DNS, registration, HTTP, TLS, certificate transparency, and port scan commands. They show what the internet can see of the organisation. Each command sends traffic from the host that runs it. The target can log the source address. The `nmap` commands in this file were checked against vendor docs only, not against a local CLI.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [DNS records](#dns-records)
  - [NET-01 Query address and alias records](#net-01-query-address-and-alias-records)
  - [NET-02 Query mail, text, name server, and CAA records](#net-02-query-mail-text-name-server-and-caa-records)
  - [NET-03 Print a short DNS answer](#net-03-print-a-short-dns-answer)
  - [NET-04 Query a chosen resolver](#net-04-query-a-chosen-resolver)
  - [NET-05 Trace DNS delegation from the root](#net-05-trace-dns-delegation-from-the-root)
- [Registration records](#registration-records)
  - [NET-06 Read the registration record of a domain](#net-06-read-the-registration-record-of-a-domain)
  - [NET-07 Read the registration record of an IP address](#net-07-read-the-registration-record-of-an-ip-address)
- [HTTP checks](#http-checks)
  - [NET-08 Check the HTTP status of a URL](#net-08-check-the-http-status-of-a-url)
  - [NET-09 Send a request to an IP address with a Host header](#net-09-send-a-request-to-an-ip-address-with-a-host-header)
  - [NET-10 Pin a hostname to an IP address and check the certificate result](#net-10-pin-a-hostname-to-an-ip-address-and-check-the-certificate-result)
- [TLS certificates](#tls-certificates)
  - [NET-11 Read the served certificate with OpenSSL 1.1.1 or later](#net-11-read-the-served-certificate-with-openssl-111-or-later)
  - [NET-12 Read the served certificate with LibreSSL](#net-12-read-the-served-certificate-with-libressl)
  - [NET-13 Read the certificate that an origin IP address serves](#net-13-read-the-certificate-that-an-origin-ip-address-serves)
  - [NET-14 Search certificate transparency logs for a domain](#net-14-search-certificate-transparency-logs-for-a-domain)
- [Port scans of own hosts](#port-scans-of-own-hosts)
  - [NET-15 Scan the top TCP ports with a connect scan](#net-15-scan-the-top-tcp-ports-with-a-connect-scan)
  - [NET-16 Detect service versions on open ports](#net-16-detect-service-versions-on-open-ports)
  - [NET-17 List the TLS ciphers that a port accepts](#net-17-list-the-tls-ciphers-that-a-port-accepts)

## DNS records

NET-01 queries only address and alias records. NET-02 and NET-03 carry the SENSITIVE tag, because TXT records and other record types can hold a mailbox or a person's name. All three use the default resolver of the host. NET-01 stays untagged only when the human confirms that the default resolver is a public resolver. Then NET-01 can query any name, including an indicator from the incident (safety rule 10 in `../SKILL.md`). An internal resolver can return internal records, which are network layout. In that case, ask the human first. The resolver sends the query to the name servers of that name. An attacker who runs those name servers can see the query. A query also tells the resolver which name you investigate.

### NET-01 Query address and alias records

- Purpose: show which addresses and aliases a name resolves to. Phase: triage.
- Label: READ-ONLY
- Permission: none. The command sends DNS queries from this host.
- Command: run the check first. `dig` applies the options in `${HOME}/.digrc` before the command line. That file can add `+trace` or another option. Then `dig` sends queries to other servers. When the output is `digrc exists`, stop. NET-01 then needs human approval.

  ```bash
  test -e "$HOME/.digrc" && echo 'digrc exists' || echo 'no digrc'
  ```

  ```bash
  dig +noall +answer <hostname> A
  dig +noall +answer <hostname> AAAA
  dig +noall +answer <hostname> CNAME
  ```

- Output: one line per record with name, TTL, class, type, and value. Look for: an address that the organisation does not own, an alias to an unknown name, or a very short TTL.
- Doc: https://bind9.readthedocs.io/en/latest/manpages.html (checked 2026-11-12)
- Local help: checked with dig (`dig -h` and `man dig`). `+noall +answer` and the query types are in the usage text. `man dig` names `${HOME}/.digrc`.

### NET-02 Query mail, text, name server, and CAA records

- Purpose: check mail routing, ownership tokens, delegation, and which certificate authorities may issue. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends DNS queries from this host.
- Command:

  ```bash
  dig +noall +answer <domain> MX
  dig +noall +answer <domain> TXT
  dig +noall +answer <domain> NS
  dig +noall +answer <domain> CAA
  ```

- Output: one line per record. Look for: a mail host that you do not know, or a TXT token for an unknown service. Also look for a name server outside the DNS provider, or a CAA record that names an unknown authority.
- Approval: ask the human first.
- Doc: https://bind9.readthedocs.io/en/latest/manpages.html (checked 2026-11-12)
- Local help: checked with dig (`dig -h`). The usage text does not list CAA. If dig rejects `CAA`, use `TYPE257`. The dig manual says `TYPEnn` is accepted.

### NET-03 Print a short DNS answer

- Purpose: print only the answer values, for a quick comparison or a script. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends a DNS query from this host.
- Command:

  ```bash
  dig +short <hostname> <record-type>
  ```

- Output: one value per line. Look for: a value that differs from the expected one. Empty output does not prove that the record is absent, because a DNS failure can also give no answer. Before you report a record as absent, run `dig <hostname> <record-type>` without `+short`. That is a separate command. Ask the human again. Save its output to a new file. Read `status:` in the header. `NXDOMAIN` means the name does not exist. `NOERROR` with an empty answer section means the name has no record of that type. Any other status, such as `SERVFAIL`, means the result is unknown.
- Approval: ask the human first.
- Doc: https://bind9.readthedocs.io/en/latest/manpages.html (checked 2026-11-12)
- Local help: checked with dig (`dig -h`).

### NET-04 Query a chosen resolver

- Purpose: compare the answer of one resolver with another. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends a DNS query to `<resolver-ip>`. An internal resolver can return internal records, which are network layout.
- Command:

  ```bash
  dig @<resolver-ip> +noall +answer <hostname> <record-type>
  ```

- Output: the answer from that resolver. Look for: an answer that differs from the answer of the authoritative name server, which can mean a stale cache, a hijack, or split-horizon DNS.
- Approval: ask the human first.
- Doc: https://bind9.readthedocs.io/en/latest/manpages.html (checked 2026-11-12)
- Local help: checked with dig (`dig -h`). The usage line shows `@global-server`.

### NET-05 Trace DNS delegation from the root

- Purpose: follow the delegation from the root servers to the final answer. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends DNS queries to the root and to each name server on the path.
- Command:

  ```bash
  dig +trace <hostname> <record-type>
  ```

- Output: the answer from each server on the path. Look for: a delegation to a name server that the organisation does not run, or a path that differs from the registrar settings.
- Approval: ask the human first. The trace queries every name server on the path, also one that an attacker runs after a hijack. Name that risk in the approval request.
- Doc: https://bind9.readthedocs.io/en/latest/manpages.html (checked 2026-11-12)
- Local help: checked with dig (`dig -h`). The `+[no]trace` option is listed.

## Registration records

Registration records can name people, email addresses, and phone numbers. NET-06 and NET-07 run without approval, because they query public infrastructure (safety rule 10 in `../SKILL.md`). Keep a contact detail only in the saved output file. Do not copy it into a summary.

NET-06 and NET-07 contact only the IANA server and the one server that IANA refers to. The commands do not follow other referrals, because a referral can point to a server that the owner of the record runs. That owner can be the attacker. The commands use the macOS tool `/usr/bin/whois` with `-Q` and `-h`. `-h` names the server, so the variables `WHOIS_SERVER` and `RA_SERVER` have no effect. `-Q` stops automatic referrals.

Run this check first. When the output is not `Darwin`, stop. NET-06 and NET-07 then need human approval, because other `whois` tools read other settings and follow referrals in other ways.

```bash
uname -s
```

### NET-06 Read the registration record of a domain

- Purpose: find the registrar, the dates, and the name servers of a domain. Phase: scoping.
- Label: READ-ONLY
- Permission: none. The command queries two registry servers over TCP port 43.
- Command: run the two steps in order.
  1. Ask the IANA server. Save the output.

     ```bash
     /usr/bin/whois -Q -h whois.iana.org <domain>
     ```

  2. Read the `refer:` line. It names the WHOIS server of the top-level domain registry. Use that value as `<registry-host>` only when it passes the hostname check in safety rule 7. When the line is absent, stop and tell the human.

     ```bash
     /usr/bin/whois -Q -h <registry-host> <domain>
     ```

- Output: registrar, creation and expiry dates, name servers, and sometimes contacts. Look for: a recent creation date on a look-alike domain, a registrar change, or an expiry date in the past. The output can name a registrar WHOIS server. Ask the human before you query that server. The query tells the registry operators which domain you check.
- Doc: https://www.rfc-editor.org/rfc/rfc3912, https://www.iana.org/help/whois, and https://man.freebsd.org/cgi/man.cgi?query=whois&sektion=1 (checked 2026-11-12)
- Local help: checked with macOS `whois` (`man whois`). The manual says that `-Q` does not follow referrals and that `-h` selects the server.

### NET-07 Read the registration record of an IP address

- Purpose: find the network owner of an address that appears in a log. Phase: triage.
- Label: READ-ONLY
- Permission: none. The command queries two registry servers over TCP port 43.
- Command: run the two steps in order.
  1. Ask the IANA server. Save the output.

     ```bash
     /usr/bin/whois -Q -h whois.iana.org <ip-address>
     ```

  2. Read the `refer:` line. It names the WHOIS server of the regional internet registry. Use that value as `<registry-host>` only when it passes the hostname check in safety rule 7. When the line is absent, stop and tell the human.

     ```bash
     /usr/bin/whois -Q -h <registry-host> <ip-address>
     ```

- Output: network range, owner organisation, country, and abuse contact. Look for: a hosting provider, a VPN service, or a country that the organisation does not serve. The output can hold a `ReferralServer:` line. That server can belong to the network owner. Do not query it without human approval. The query tells the registry operators which address you check.
- Doc: https://www.rfc-editor.org/rfc/rfc3912, https://www.iana.org/help/whois, and https://man.freebsd.org/cgi/man.cgi?query=whois&sektion=1 (checked 2026-11-12)
- Local help: checked with macOS `whois` (`man whois`).

## HTTP checks

These entries send requests to a URL that the organisation owns. Use a path that only reads data. Each command puts the URL in single quotes, so that the shell does not read a `;` or a `&` in the path. Check the path against safety rule 7 in `../SKILL.md` first. Each `curl` command starts with `-q`, so that curl does not read a `.curlrc` file. Such a file can add options, for example one that follows a redirect to another host. NET-08, NET-09, and NET-10 use `--noproxy '*'`, so that curl connects directly and ignores a proxy in the environment. For an IPv6 origin, put the address in brackets, such as `[<origin-ipv6>]`. The curl manual says to give IPv6 addresses within brackets. Some servers answer HEAD and GET differently. NET-08 stays untagged only for a URL that the human confirms the organisation owns. NET-09 and NET-10 send direct requests to an origin, so they carry the SENSITIVE tag.

### NET-08 Check the HTTP status of a URL

- Purpose: read the status code of a URL without the body. Phase: verification.
- Label: READ-ONLY
- Permission: none. The command sends one HEAD request.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -o /dev/null -I -w '%{http_code}\n' --connect-timeout 5 --max-time 15 'https://<hostname>/<url-path>'
  ```

- Output: one status code. Look for: 200 where the path should be blocked, or 403 or 404 where the path should work.
- Doc: https://curl.se/docs/manpage.html (checked 2026-11-12)
- Local help: checked with curl (`curl --help all` and `man curl`).

### NET-09 Send a request to an IP address with a Host header

- Purpose: test whether an origin answers directly and skips the CDN or WAF. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends one GET request to `<origin-ip>`.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -o /dev/null -w '%{http_code} %{remote_ip}\n' -H 'Host: <hostname>' --connect-timeout 5 --max-time 15 'http://<origin-ip>/<url-path>'
  ```

- Output: the status code and the IP that answered. When that IP is not `<origin-ip>`, the request did not test the origin. Stop and tell the human. Look for: a 200 or a redirect from the origin. This means the origin accepts traffic that did not pass the CDN. For HTTPS, use NET-10.
- Approval: ask the human first. Run this command only against an origin that the human confirms the organisation owns.
- Doc: https://curl.se/docs/manpage.html (checked 2026-11-12)
- Local help: checked with curl (`curl --help all`). The `-H` option replaces the Host header that curl builds.

### NET-10 Pin a hostname to an IP address and check the certificate result

- Purpose: test an origin over HTTPS with the correct name and SNI. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command sends one HEAD request to `<origin-ip>`.
- Command:

  ```bash
  curl -q -sS --noproxy '*' -o /dev/null -I -w 'code=%{http_code} ip=%{remote_ip} verify=%{ssl_verify_result}\n' --resolve '<hostname>:443:<origin-ip>' --connect-timeout 5 --max-time 15 'https://<hostname>/<url-path>'
  ```

- Output: the status code, the IP address that curl used, and the verification result. `verify=0` means the certificate check passed. Look for: a 200 from the origin, `ip` not equal to `<origin-ip>`, or `verify` not equal to 0.
- Approval: ask the human first. Run this command only against an origin that the human confirms the organisation owns.
- Doc: https://curl.se/docs/manpage.html (checked 2026-11-12)
- Local help: checked with curl (`man curl`). The `--resolve`, `remote_ip`, and `ssl_verify_result` entries were read.

## TLS certificates

NET-11 and NET-12 carry the SENSITIVE tag, because a certificate can hold an email address. Run them only for a host that the human confirms the organisation owns. A TLS connection to an attacker's host can warn the attacker.

### NET-11 Read the served certificate with OpenSSL 1.1.1 or later

- Purpose: read the subject, issuer, dates, and alternative names of the certificate that a public host serves. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command opens one TLS connection to port 443.
- Command:

  ```bash
  openssl s_client -connect <hostname>:443 -servername <hostname> </dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
  ```

- Output: `subject=`, `issuer=`, `notBefore=`, `notAfter=`, and the subjectAltName list. Look for: an expired date, an issuer that you do not expect, or a name that the organisation does not own.
- Approval: ask the human first.
- Doc: https://docs.openssl.org/master/man1/openssl-s_client/ and https://docs.openssl.org/master/man1/openssl-x509/ (checked 2026-11-12)
- Local help: `openssl x509 -help` on LibreSSL 3.3.6, the `/usr/bin/openssl` in macOS 26, shows no `-ext` option. Use NET-12 on macOS.

### NET-12 Read the served certificate with LibreSSL

- Purpose: read the same certificate data on a host without the `-ext` option. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command opens one TLS connection to port 443.
- Command:

  ```bash
  openssl s_client -connect <hostname>:443 -servername <hostname> </dev/null | openssl x509 -noout -subject -issuer -dates -text
  ```

- Output: subject, issuer, and dates, then the full certificate text. Read the "X509v3 Subject Alternative Name" block for the names. Look for: an expired date, an unknown issuer, or a name that the organisation does not own.
- Approval: ask the human first.
- Doc: https://docs.openssl.org/master/man1/openssl-x509/ (checked 2026-11-12)
- Local help: checked with LibreSSL (`openssl s_client -help` and `openssl x509 -help`). The `-connect`, `-servername`, `-noout`, `-subject`, `-issuer`, `-dates`, and `-text` options are listed.

### NET-13 Read the certificate that an origin IP address serves

- Purpose: compare the certificate at the origin with the public certificate. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. The command opens one TLS connection to `<origin-ip>` on port 443.
- Command:

  ```bash
  openssl s_client -connect <origin-ip>:443 -servername <hostname> </dev/null | openssl x509 -noout -subject -issuer -dates -text
  ```

- Output: the certificate that the origin presents for `<hostname>`. For an IPv6 origin, use `-connect '[<origin-ipv6>]:443'`. The OpenSSL manual says that an IPv6 address needs brackets. Look for: a self-signed certificate, a different issuer from NET-12, or internal names in the alternative names.
- Approval: ask the human first.
- Doc: https://docs.openssl.org/master/man1/openssl-s_client/ (checked 2026-11-12)
- Local help: checked with LibreSSL (`openssl s_client -help`).

### NET-14 Search certificate transparency logs for a domain

- Purpose: list the certificates that public logs hold for a domain. Phase: scoping.
- Label: READ-ONLY
- Permission: none. The command sends one HTTPS request to a public search service.
- Command:

  ```bash
  (set -o pipefail; curl -q -sS --noproxy '*' --fail --max-time 60 'https://crt.sh/?q=<domain>&output=json' | jq -r '.[] | [.id, .entry_timestamp, .not_before, .not_after, .issuer_name, .common_name, .name_value] | @tsv')
  ```

- Output: one tab-separated line per certificate. A non-zero exit status or any error message means the result is incomplete. In that case, an empty result does not show that no certificate exists. Look for: a certificate that the organisation did not request, a new name that you do not know, or an unexpected issuer. Results can hold email addresses. Keep an email address only in the saved output file. Do not copy it into a summary. The query tells the crt.sh operator which domain you check. This command runs without approval, because it queries public infrastructure.
- Doc: https://jqlang.org/manual/ for `@tsv` (checked 2026-11-12). No public vendor page documents the crt.sh JSON fields. The crt.sh home page returned HTTP 404 when fetched.
- Local help: checked with jq (`jq --help`) and curl (`curl --help all`). The field names in the jq filter are not confirmed. Run `jq '.[0]'` on a small result first to check them.

## Port scans of own hosts

Run each nmap entry only against hosts that the human confirms the organisation owns and authorises. A scan of any other host can break the law and the rules of the network provider. A scan sends traffic and returns internal context, so each entry carries the SENSITIVE tag. `<target-ip>` is one literal IP address that the human confirms the organisation owns and authorises for the scan. Do not use a hostname. Nmap resolves a hostname and scans only the first address ([nmap target specification](https://nmap.org/book/man-target-specification.html)). A proxied hostname, for example one behind Cloudflare, resolves to an address of the proxy, not of the organisation's host ([how Cloudflare works](https://developers.cloudflare.com/fundamentals/concepts/how-cloudflare-works/)). Ask the human to approve each further IP address separately. Do not use a CIDR range, an address range, braces, or a list. Nmap and the shell expand them to more hosts (safety rule 7 in `../SKILL.md`). If a host shows as down but you know it is up, the human can add `-Pn` to skip host discovery. For an IPv6 `<target-ip>`, use the second command line of each entry, which adds `-6`. Ping scans, port scans, version detection, and scripts support IPv6 ([nmap -6 option](https://nmap.org/book/man-misc-options.html)).

### NET-15 Scan the top TCP ports with a connect scan

- Purpose: list open TCP ports on a host that the organisation owns. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. A connect scan needs no raw packet privilege. Run only against hosts that the human confirms the organisation owns and authorises.
- Command:

  ```bash
  nmap -sT --top-ports <port-count> <target-ip>
  nmap -6 -sT --top-ports <port-count> <target-ip>
  ```

- Output: one line per port with state and service name. Look for: open ports that the host should not expose, such as database, remote admin, or debug ports.
- Cost note: no fee. Scans can trigger alerts at the target, at the network provider, and in security tools. A connect scan also adds log lines on the target. Warn the owners first.
- Approval: ask the human first.
- Doc: https://nmap.org/book/man-port-scanning-techniques.html and https://nmap.org/book/man-port-specification.html (checked 2026-11-12)

### NET-16 Detect service versions on open ports

- Purpose: identify the software and version behind each open port. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Run only against hosts that the human confirms the organisation owns and authorises.
- Command:

  ```bash
  nmap -sT -sV --version-intensity 5 -p <port-list> <target-ip>
  nmap -6 -sT -sV --version-intensity 5 -p <port-list> <target-ip>
  ```

- Output: port, state, service, and version string. Look for: outdated software, a service on an unexpected port, or a version string that names a known vulnerable release.
- Cost note: no fee. Version detection sends probes to each service, so it is more likely to raise alerts than NET-15. The probes send data that a service does not expect. The nmap docs do not say that this can crash a service. Ask the owners about fragile services first. Warn the owners first.
- Approval: ask the human first.
- Doc: https://nmap.org/book/man-version-detection.html (checked 2026-11-12)

### NET-17 List the TLS ciphers that a port accepts

- Purpose: find weak TLS protocol versions and ciphers on a service. Phase: verification.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Run only against hosts that the human confirms the organisation owns and authorises.
- Command:

  ```bash
  nmap -sT --script ssl-enum-ciphers -p <port> <target-ip>
  nmap -6 -sT --script ssl-enum-ciphers -p <port> <target-ip>
  ```

- Output: protocol versions, ciphers with a grade from A to F, and a "least strength" line. Look for: SSLv3, TLS 1.0, a grade below A, or a certificate warning.
- Cost note: no fee. The script is marked intrusive and opens many connections, so monitoring tools will likely see it. Nmap marks a script intrusive for one of two reasons. The risk that it crashes the target is too high, or it uses significant resources on the target. Warn the owners first.
- Approval: ask the human first.
- Doc: https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html and https://nmap.org/book/nse-usage.html for the intrusive category (checked 2026-11-12)
