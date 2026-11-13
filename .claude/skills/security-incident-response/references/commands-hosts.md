# Linux and macOS host commands

This file has commands to inspect a host, hash files, capture memory and disk, and record chain of custody. A human must give the agent a shell on the host first. The Linux-only commands in this file were checked against vendor docs only, not against a local CLI.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

Collect the most volatile data first. RFC 3227 section 2.1 gives this order:

1. Registers and cache.
2. The routing table, ARP cache, process table, kernel statistics, and memory.
3. Temporary file systems.
4. Disk.
5. Remote logs.
6. Network layout.
7. Archive media.

Write each output to evidence storage, not to the suspect disk.

## Contents

- [Processes](#processes)
  - [HOST-01 List running processes with full command lines](#host-01-list-running-processes-with-full-command-lines)
  - [HOST-02 List Linux processes with parent and start time](#host-02-list-linux-processes-with-parent-and-start-time)
  - [HOST-03 List macOS processes with parent and start time](#host-03-list-macos-processes-with-parent-and-start-time)
  - [HOST-04 Inspect one Linux process from its proc entries](#host-04-inspect-one-linux-process-from-its-proc-entries)
- [Network connections](#network-connections)
  - [HOST-05 List Linux sockets with process names](#host-05-list-linux-sockets-with-process-names)
  - [HOST-06 List network files with lsof](#host-06-list-network-files-with-lsof)
  - [HOST-07 List macOS connections with netstat](#host-07-list-macos-connections-with-netstat)
- [Persistence on Linux](#persistence-on-linux)
  - [HOST-08 List system cron files](#host-08-list-system-cron-files)
  - [HOST-09 Show the crontab of one user](#host-09-show-the-crontab-of-one-user)
  - [HOST-10 List systemd services and timers](#host-10-list-systemd-services-and-timers)
  - [HOST-11 List systemd unit file folders](#host-11-list-systemd-unit-file-folders)
  - [HOST-12 Show SSH authorised keys](#host-12-show-ssh-authorised-keys)
  - [HOST-13 Show rc.local and ld.so.preload](#host-13-show-rclocal-and-ldsopreload)
  - [HOST-14 Show shell profile files](#host-14-show-shell-profile-files)
- [Persistence on macOS](#persistence-on-macos)
  - [HOST-15 List launchd job folders](#host-15-list-launchd-job-folders)
  - [HOST-16 Read one launchd job file](#host-16-read-one-launchd-job-file)
  - [HOST-17 List loaded launchd jobs](#host-17-list-loaded-launchd-jobs)
  - [HOST-18 List configuration profiles](#host-18-list-configuration-profiles)
  - [HOST-34 List login items and background items](#host-34-list-login-items-and-background-items)
- [Recent logins](#recent-logins)
  - [HOST-19 Show recent logins on Linux](#host-19-show-recent-logins-on-linux)
  - [HOST-20 Show failed logins on Linux](#host-20-show-failed-logins-on-linux)
  - [HOST-21 Show recent logins on macOS](#host-21-show-recent-logins-on-macos)
  - [HOST-22 Show who is logged in now](#host-22-show-who-is-logged-in-now)
  - [HOST-23 Read SSH events from the systemd journal](#host-23-read-ssh-events-from-the-systemd-journal)
  - [HOST-24 Search the Linux authentication log](#host-24-search-the-linux-authentication-log)
  - [HOST-25 Read login and SSH events from the macOS log](#host-25-read-login-and-ssh-events-from-the-macos-log)
- [File hashes](#file-hashes)
  - [HOST-26 Hash one file on Linux](#host-26-hash-one-file-on-linux)
  - [HOST-27 Hash one file on macOS](#host-27-hash-one-file-on-macos)
  - [HOST-28 Hash every file in an evidence folder on Linux](#host-28-hash-every-file-in-an-evidence-folder-on-linux)
  - [HOST-29 Hash every file in an evidence folder on macOS](#host-29-hash-every-file-in-an-evidence-folder-on-macos)
  - [HOST-30 Check files against a hash manifest](#host-30-check-files-against-a-hash-manifest)
- [Memory capture](#memory-capture)
  - [HOST-31 Capture Linux memory with AVML](#host-31-capture-linux-memory-with-avml)
  - [HOST-32 Capture Linux memory with LiME](#host-32-capture-linux-memory-with-lime)
  - [macOS memory capture note](#macos-memory-capture-note)
- [Disk capture](#disk-capture)
  - [HOST-33 Copy a Linux disk to an image with dd](#host-33-copy-a-linux-disk-to-an-image-with-dd)
- [Chain of custody](#chain-of-custody)

## Processes

Process listings show command lines and user names. These entries carry the SENSITIVE tag. A command line can hold a token or a password. Follow safety rule 15 in `../SKILL.md` when one appears.

### HOST-01 List running processes with full command lines

- Purpose: list every process with its owner and full command line. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Any user can run it. Run as `root` only if the human requires it.
- Command:

  ```bash
  ps auxww
  ```

- Output: user, PID, CPU and memory use, start time, and the full command. Look for: a process that runs from `/tmp` or `/dev/shm`, a name that imitates a system process, or a miner or shell that uses the network.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/ps.1.html (checked 2026-11-12). The `ww` option gives unlimited width.
- Local help: checked on macOS (`man ps`). The `-a`, `-x`, and `-w` options are listed. The page does not describe the BSD `u` option, but macOS accepts `ps aux`.

### HOST-02 List Linux processes with parent and start time

- Purpose: show the process tree links and the exact start time of each process. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Any user can run it.
- Command:

  ```bash
  ps -eo pid,ppid,user,lstart,cmd
  ```

- Output: PID, parent PID, user, start time, and command. Look for: a start time close to the first alert, a parent PID of 1 for a shell, or a web server that has a shell as a child.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/ps.1.html (checked 2026-11-12)

### HOST-03 List macOS processes with parent and start time

- Purpose: show the process tree links and the exact start time of each process. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Any user can run it.
- Command:

  ```bash
  ps -axo pid,ppid,user,lstart,command
  ```

- Output: PID, parent PID, user, start time, and command. Look for: a start time close to the first alert, a shell started by an app that does not need one, or a binary in a user folder.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man ps`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12).
- Local help: checked on macOS (`man ps`). The `lstart`, `command`, `ppid`, and `user` keywords are listed.

### HOST-04 Inspect one Linux process from its proc entries

- Purpose: read the real executable path and the command line of one process. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: the same user as the process, or `root`. The kernel applies a ptrace read check to `/proc/<pid>/exe`.
- Command:

  ```bash
  ls -l /proc/<pid>/exe
  tr '\0' '\n' < /proc/<pid>/cmdline
  ```

- Output: the link target of the executable and one argument per line. Look for: a target path that ends in ` (deleted)`, a path in `/tmp` or `/dev/shm`, or a command line that differs from the `ps` output. A process can rewrite its own arguments.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man5/proc_pid_exe.5.html and https://man7.org/linux/man-pages/man5/proc_pid_cmdline.5.html (checked 2026-11-12)

## Network connections

Connection listings show remote addresses and process names. These entries carry the SENSITIVE tag.

### HOST-05 List Linux sockets with process names

- Purpose: list TCP and UDP sockets with the owning process. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` to see process names of other users. The doc page does not state the privilege for `-p`.
- Command:

  ```bash
  ss -tunap
  ```

- Output: protocol, state, queue sizes, local address and port, peer address and port, and process. Look for: a listener on an unexpected port, an established connection to an unknown address, or outbound traffic from a database or web process.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man8/ss.8.html (checked 2026-11-12)

### HOST-06 List network files with lsof

- Purpose: list open network sockets and the processes that hold them. It works on Linux and macOS. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` for all users. Without it, lsof lists only what the calling user may see.
- Command:

  ```bash
  lsof -nP -i
  ```

- Output: command, PID, user, protocol, and local and remote address with port. The `-n` and `-P` options stop name lookups. Look for: a remote address that you do not know, or a listener from a user process.
- Approval: ask the human first.
- Doc: https://lsof.readthedocs.io/en/latest/manpage/ (checked 2026-11-12). This is the manual of the lsof project. macOS ships its own build, so check `man lsof` on the Mac too.
- Local help: checked on macOS (`man lsof`). The `-i`, `-n`, and `-P` options are listed.

### HOST-07 List macOS connections with netstat

- Purpose: list all sockets with numeric addresses on macOS. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none. Any user can run it.
- Command:

  ```bash
  netstat -anv
  ```

- Output: protocol, queue sizes, local and foreign address, and state. The man page does not say that `-v` adds a PID column. If the output shows no PID, use HOST-06. Look for: an established connection to an unknown address.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man netstat`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12).
- Local help: checked on macOS (`man netstat`). The `-a`, `-n`, and `-v` options are listed.

## Persistence on Linux

An attacker can use each location in this section to run code again after a reboot or a login. All entries carry the SENSITIVE tag. Note the file times with the listings. A new time near the first alert is a lead. Cron files, `rc.local`, and profile files can hold a token or a password. Follow safety rule 15 in `../SKILL.md` when one appears.

### HOST-08 List system cron files

- Purpose: show the system cron tables and the cron folders. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none for most files. `root` for files that are not world readable.
- Command:

  ```bash
  ls -la --time-style=full-iso /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly
  cat /etc/crontab
  ```

- Output: file names with times, and the table in `/etc/crontab`. Look for: a file that no package owns, a job that runs a script from `/tmp`, or a job that calls `curl`, `wget`, or a shell with a remote address.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/crontab.1.html (checked 2026-11-12). The page covers per-user tables only. It does not describe the folder names above.

### HOST-09 Show the crontab of one user

- Purpose: show the scheduled jobs of one user. It works on Linux and macOS. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` to read the crontab of another user. The doc page does not state who may use `-u`.
- Command:

  ```bash
  crontab -l -u <user>
  ```

- Output: the job lines of that user. Look for: a job that downloads or runs code, a job that runs every minute, or a job for a user that should have none. On macOS, `launchd` runs most scheduled jobs. See HOST-15.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/crontab.1.html (checked 2026-11-12)
- Local help: checked on macOS (`man crontab`). The `-l` and `-u` options are listed.

### HOST-10 List systemd services and timers

- Purpose: list installed service files and timers. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none.
- Command:

  ```bash
  systemctl list-unit-files --type=service --no-pager
  systemctl list-timers --all --no-pager
  ```

- Output: unit names with enablement state, and each timer with its next and last run and the service that it starts. Look for: an enabled unit with a name that imitates a system unit, or a timer that starts an unknown service.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/systemctl.1.html and https://man7.org/linux/man-pages/man5/systemd.timer.5.html (checked 2026-11-12)

### HOST-11 List systemd unit file folders

- Purpose: show unit files in the folders where administrators and attackers add them. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none for most files. `root` for files that are not world readable.
- Command:

  ```bash
  ls -la --time-style=full-iso /etc/systemd/system /run/systemd/system /usr/local/lib/systemd/system /usr/lib/systemd/system /etc/systemd/user /home/<user>/.config/systemd/user
  ```

- Output: unit file names and times. A file in an earlier folder overrides a file with the same name in a later folder. Look for: a recent `.service` or `.timer` file, or a file that overrides a system unit. Read a suspect file with `systemctl cat <unit-name>`.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man5/systemd.unit.5.html (checked 2026-11-12)

### HOST-12 Show SSH authorised keys

- Purpose: list the public keys that can log in as a user. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` to read the files of other users.
- Command:

  ```bash
  ls -la --time-style=full-iso /home/<user>/.ssh /root/.ssh
  cat /home/<user>/.ssh/authorized_keys /home/<user>/.ssh/authorized_keys2 /root/.ssh/authorized_keys /root/.ssh/authorized_keys2
  ```

- Output: file times, then one public key per line with optional settings and a comment. The `AuthorizedKeysFile` setting in `/etc/ssh/sshd_config` can name other files. Look for: a key that no person can claim, a `command=` setting, or a file time near the first alert. This command never reads private keys.
- Approval: ask the human first.
- Doc: https://man.openbsd.org/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT (checked 2026-11-12). This is the OpenSSH manual. It names `~/.ssh/authorized_keys` and `~/.ssh/authorized_keys2` as the default files when `AuthorizedKeysFile` is not set.

### HOST-13 Show rc.local and ld.so.preload

- Purpose: check two files that run or load code at boot or at every program start. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none for most files. `root` for files that are not world readable.
- Command:

  ```bash
  ls -la --time-style=full-iso /etc/rc.local /etc/ld.so.preload
  cat /etc/rc.local /etc/ld.so.preload
  ```

- Output: file times and file contents. A "No such file" message is normal for a file that the host does not use. Look for: any entry in `/etc/ld.so.preload`. The loader loads each listed library before all others. An unknown entry can hide processes or files. Also look for network commands in `/etc/rc.local`.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man8/ld.so.8.html (checked 2026-11-12)

### HOST-14 Show shell profile files

- Purpose: find commands that run at every login or shell start. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` to read the files of other users.
- Command:

  ```bash
  ls -la --time-style=full-iso /etc/profile /etc/profile.d /etc/bash.bashrc /home/<user>/.bashrc /home/<user>/.bash_profile /home/<user>/.bash_login /home/<user>/.bash_logout /home/<user>/.profile
  awk '{ u = toupper($0); if (u ~ /KEY|TOKEN|SECRET|PASS|AUTH|BEARER|CREDENTIAL/) print FILENAME ":" FNR ": <masked>"; else print FILENAME ":" FNR ": " $0 }' /home/<user>/.bashrc /home/<user>/.bash_profile /home/<user>/.bash_login /home/<user>/.profile
  ```

- Output: file times, then each line with its file name and line number. Profile files often export tokens. The `awk` command prints `<masked>` for each line that holds a word such as `TOKEN`, `KEY`, or `PASS`. A human reads each masked line in the file. Masking is not complete, so safety rule 15 in `../SKILL.md` still applies. Some files do not exist on every host. For zsh, the files are `/etc/zshenv`, `/etc/zprofile`, `/etc/zshrc`, `/etc/zlogin`, `/etc/zlogout`, and the same names with a leading dot in `$ZDOTDIR` or the home folder. Look for: an added line that downloads code, sets `LD_PRELOAD`, starts a hidden process, or defines an alias for `sudo` or `ssh`.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html, https://zsh.sourceforge.io/Doc/Release/Files.html, and https://pubs.opengroup.org/onlinepubs/9799919799/utilities/awk.html (checked 2026-11-12). `/etc/bash.bashrc` and `/etc/profile.d` are distribution additions. The bash manual does not name them.
- Local help: The `awk` program uses only `toupper`, `FNR`, `FILENAME`, `~`, and `print`, which the POSIX page defines. The program was not run on a test file.

## Persistence on macOS

These entries cover the folders and commands that macOS documents. HOST-34 lists login items and background items from the command line. A human can also open System Settings, General, then Login Items & Extensions. Apple documents that pane at https://support.apple.com/guide/mac-help/open-items-automatically-when-you-log-in-mtusr003/mac (checked 2026-11-12).

### HOST-15 List launchd job folders

- Purpose: list the files that launchd loads for daemons and agents. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: none for most files.
- Command:

  ```bash
  ls -la /Library/LaunchDaemons /Library/LaunchAgents /Users/<user>/Library/LaunchAgents /System/Library/LaunchDaemons /System/Library/LaunchAgents
  ```

- Output: the names and times of property list files. Files in `/System` belong to Apple. Look for: a recent file in `/Library` or in a user folder, a name that imitates an Apple label, or a vendor that the organisation does not use.
- Approval: ask the human first.
- Doc: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html (checked 2026-11-12)
- Local help: checked on macOS (`man launchctl` for the job model).

### HOST-16 Read one launchd job file

- Purpose: show what one launchd job runs and when. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the file.
- Command:

  ```bash
  plutil -p <plist-path>
  ```

- Output: the keys of the job, such as `Label`, `ProgramArguments`, `RunAtLoad`, and `KeepAlive`. The man page says that the format is for people, not scripts. An `EnvironmentVariables` key can hold a secret value. Follow safety rule 15 in `../SKILL.md` when one appears. Look for: a program in `/tmp` or in a user folder, a `RunAtLoad` or `KeepAlive` value of true on an unknown job, or a command that runs a shell.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man plutil`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12). The `EnvironmentVariables` key is in `man launchd.plist`.
- Local help: checked on macOS (`man plutil`). The `-p` option is listed.

### HOST-17 List loaded launchd jobs

- Purpose: list the launchd jobs that are loaded now. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none.
- Command:

  ```bash
  launchctl list
  ```

- Output: three columns with PID, last exit status, and label. A PID shows only for a running job. The man page calls `print` the recommended alternative. Look for: a label that you cannot match to an installed app, or a job that exits with an error repeatedly.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man launchctl`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12). The Apple launchd page in HOST-15 does not describe `launchctl`.
- Local help: checked on macOS (`man launchctl`). The `list` subcommand is listed.

### HOST-18 List configuration profiles

- Purpose: list the configuration profiles that are installed on the Mac. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` to list the profiles of the device. A normal user sees the profiles of that user.
- Command:

  ```bash
  profiles list -type configuration
  ```

- Output: the profile names and identifiers. Look for: a profile that the organisation did not push, a profile that adds a certificate, a proxy, a VPN, or a DNS setting, or an unknown management server.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man profiles`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12).
- Local help: checked on macOS (`man profiles`). The `list` verb and the `-type configuration` option are listed. The page says that the tool cannot install profiles on macOS 11 or later.

### HOST-34 List login items and background items

- Purpose: list the login items, background items, and launchd jobs that macOS tracks for each user. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the Apple page does not state one. Run it as the logged-in user. Use `sudo` only when the human approves it.
- Command:

  ```bash
  sfltool dumpbtm
  ```

- Output: the status of each login item and background item. Apple says the output includes "loaded servicemanagement payload UUIDs". The Apple page does not describe the other fields. Look for: an item from a developer that the organisation does not use. Also look for an item in a user folder or `/tmp`, or an enabled item that the user did not add.
- Approval: ask the human first.
- Doc: https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web (checked 2026-11-12). The page says `dumpbtm` "Prints the current status of login and background items". Do not run `sfltool resetbtm`, because it resets that data.
- Local help: checked on macOS (`sfltool help`). The usage line lists `dumpbtm`. The local man page (`man sfltool`) describes only `archive`.

## Recent logins

Login records name users and source addresses. These entries carry the SENSITIVE tag.

### HOST-19 Show recent logins on Linux

- Purpose: list the most recent logins and reboots from the login record file. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `/var/log/wtmp`.
- Command:

  ```bash
  last -i -w -n <line-count>
  ```

- Output: user, terminal, source IP address, login time, and duration. Look for: a login from an address that you do not know, a login at an odd hour, or a user that never logs in. The output may omit the year. Check the file dates.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/last.1.html (checked 2026-11-12)
- Local help: The `last` implementation differs between distributions. The three options above appear on the page that was read.

### HOST-20 Show failed logins on Linux

- Purpose: list failed login attempts from the failed login file. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `root`. The file is `/var/log/btmp` on most hosts.
- Command:

  ```bash
  lastb -i -w -n <line-count>
  ```

- Output: the user name that was tried, terminal, source IP address, and time. Look for: many tries from one address, a spread of user names from one address, or a success in HOST-19 from the same address.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/last.1.html (checked 2026-11-12). The page that was read does not describe `lastb`.

### HOST-21 Show recent logins on macOS

- Purpose: list recent logins from the login record. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to `/var/log/utx.log`.
- Command:

  ```bash
  last -n <line-count>
  ```

- Output: user, terminal, host, start and stop times, and duration. Look for: a login from a remote host, a login at an odd hour, or a user that the person does not use.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man last`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12).
- Local help: checked on macOS (`man last`). The `-n` option is listed. The default file is `/var/log/utx.log`.

### HOST-22 Show who is logged in now

- Purpose: list the active sessions and what each user runs. It works on Linux and macOS. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: none.
- Command:

  ```bash
  w
  who -a
  ```

- Output: user, terminal, source host, login time, idle time, and the current command. Look for: a session from an unknown host, a user that should be away, or a long idle shell.
- Approval: ask the human first.
- Doc: the local man pages on macOS (`man w` and `man who`). Apple publishes no web page for these tools (checked 2026-11-12). On Linux, see https://man7.org/linux/man-pages/man1/w.1.html and https://man7.org/linux/man-pages/man1/who.1.html.
- Local help: checked on macOS (`man who` and `man w`). The `-a` option of `who` is listed.

### HOST-23 Read SSH events from the systemd journal

- Purpose: read the log lines of the SSH server in a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root`, or a member of the `systemd-journal`, `adm`, or `wheel` group.
- Command:

  ```bash
  journalctl _COMM=sshd --since '<start-time-utc>' --until '<end-time-utc>' --utc --no-pager
  ```

- Output: log lines with time, host, and message. Write each time as `2026-01-31 13:45:00 UTC`. Look for: accepted logins from unknown addresses, many failed tries, and key or password use for a user that does not log in.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/journalctl.1.html and https://man7.org/linux/man-pages/man7/systemd.time.7.html (checked 2026-11-12)

### HOST-24 Search the Linux authentication log

- Purpose: find accepted and failed SSH logins in the text log. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` on most hosts.
- Command:

  ```bash
  grep -E 'sshd.*(Accepted|Failed|Invalid user)' /var/log/<auth-log-file>
  ```

- Output: matching log lines. `<auth-log-file>` is `auth.log` on Debian-based hosts and `secure` on Red Hat-based hosts. Look for: `Accepted` lines from unknown addresses, and `Failed` lines in bursts. Search rotated files with LOG-13.
- Approval: ask the human first.
- Doc: https://www.gnu.org/software/grep/manual/grep.html (checked 2026-11-12)
- Local help: checked on macOS (`man grep`). The `-E` option is listed.

### HOST-25 Read login and SSH events from the macOS log

- Purpose: read login and SSH log lines in a time window. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `root` may be needed. The man page says that some `log` commands require root.
- Command:

  ```bash
  log show --predicate 'process == "sshd" OR process == "loginwindow"' --start '<start-time-local>' --end '<end-time-local>' --style compact
  ```

- Output: log lines with time, process, and message. Write each time as `YYYY-MM-DD HH:MM:SS` in the local time of the Mac. Look for: SSH sessions that nobody opened, and logins at odd hours. The log store keeps a limited history.
- Approval: ask the human first.
- Doc: the local man page on macOS (`man log`). Apple publishes no web page for this tool, so the man page that ships with macOS is the source (checked 2026-11-12). The Apple web page on log messages returned only its title.
- Local help: checked on macOS (`man log`). The `show` command with `--predicate`, `--start`, `--end`, and `--style` is listed.

## File hashes

Hash files before you move or analyse them. Hash outputs hold only digests and paths, so the single-file entries stay untagged. But a hash reads the whole file, and a read can update the file's access time. On Linux, the default `relatime` mount option updates it when the old value is more than one day old, or older than the last change ([mount(8)](https://man7.org/linux/man-pages/man8/mount.8.html)). So run HOST-26, HOST-27, and HOST-30 without approval only on saved copies, capture images, or files on a read-only mount. For a live original on the suspect system, ask the human first. Record its access time with `stat` before the hash. Treat macOS the same, because this file does not check the access time rules of macOS.

### HOST-26 Hash one file on Linux

- Purpose: record the SHA-256 digest of one file. Phase: evidence.
- Label: READ-ONLY
- Permission: read access to the file. Without approval, run it only on a copy, an image, or a read-only mount. See the section intro.
- Command:

  ```bash
  sha256sum <file-path>
  ```

- Output: a 64-character digest and the file name. Look for: a digest that differs from an earlier record of the same file.
- Doc: https://man7.org/linux/man-pages/man1/sha256sum.1.html (checked 2026-11-12)

### HOST-27 Hash one file on macOS

- Purpose: record the SHA-256 digest of one file. Phase: evidence.
- Label: READ-ONLY
- Permission: read access to the file. Without approval, run it only on a copy, an image, or a read-only mount. See the section intro.
- Command:

  ```bash
  shasum -a 256 <file-path>
  ```

- Output: a 64-character digest and the file name. Look for: a digest that differs from an earlier record of the same file.
- Doc: https://perldoc.perl.org/shasum (checked 2026-11-12). macOS ships this Perl `shasum` script. The page lists `-a` and `-c`.
- Local help: checked on macOS (`man shasum`). The `-a 256` option is listed.

### HOST-28 Hash every file in an evidence folder on Linux

- Purpose: write one manifest that lists the digest of every file in a folder. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the evidence folder and write access to `<manifest-path>`.
- Command:

  ```bash
  (set -o pipefail; find '<evidence-dir>' -type f -print0 | xargs -0 sha256sum > '<manifest-path>')
  ```

- Output: one line per file with digest and path. Look for: a file count that differs from the folder. Use an absolute path for `<evidence-dir>`. A value that starts with `-` can make `find` read it as an action, such as `-delete`. Put `<manifest-path>` in the evidence folder, but outside `<evidence-dir>`, so the manifest does not hash itself. Use a path that does not exist yet, because the `>` redirect replaces an existing file. A non-zero exit status or any error message from `find` or the hash tool means the manifest is incomplete. Do not use that manifest. Tell the human, then run the command again with a new `<manifest-path>`.
- Approval: ask the human first.
- Doc: https://man7.org/linux/man-pages/man1/sha256sum.1.html (checked 2026-11-12). The `pipefail` option: https://www.gnu.org/software/bash/manual/bash.html and https://zsh.sourceforge.io/Doc/Release/Options.html (checked 2026-11-12).

### HOST-29 Hash every file in an evidence folder on macOS

- Purpose: write one manifest that lists the digest of every file in a folder. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: read access to the evidence folder and write access to `<manifest-path>`.
- Command:

  ```bash
  (set -o pipefail; find '<evidence-dir>' -type f -print0 | xargs -0 shasum -a 256 > '<manifest-path>')
  ```

- Output: one line per file with digest and path. Look for: a file count that differs from the folder. Use an absolute path for `<evidence-dir>`. A value that starts with `-` can make `find` read it as an action, such as `-delete`. Put `<manifest-path>` in the evidence folder, but outside `<evidence-dir>`, so the manifest does not hash itself. Use a path that does not exist yet, because the `>` redirect replaces an existing file. A non-zero exit status or any error message from `find` or the hash tool means the manifest is incomplete. Do not use that manifest. Tell the human, then run the command again with a new `<manifest-path>`.
- Approval: ask the human first.
- Doc: https://perldoc.perl.org/shasum (checked 2026-11-12). macOS ships this Perl `shasum` script. The page lists `-a` and `-c`. The `pipefail` option: https://www.gnu.org/software/bash/manual/bash.html and https://zsh.sourceforge.io/Doc/Release/Options.html (checked 2026-11-12).
- Local help: checked on macOS (`man shasum`). The `-a 256` option is listed. The `find` and `xargs -0` commands were not read. A local test on macOS zsh returned exit status 1 for a missing `<evidence-dir>` with `pipefail` set.

### HOST-30 Check files against a hash manifest

- Purpose: confirm that no file changed since the manifest was made. Phase: verification.
- Label: READ-ONLY
- Permission: read access to the files and the manifest. Without approval, run it only on copies, images, or files on a read-only mount. See the section intro.
- Command:

  ```bash
  sha256sum -c <manifest-path>
  shasum -a 256 -c <manifest-path>
  ```

- Output: `OK` or `FAILED` for each file. Run the first command on Linux and the second command on macOS. Look for: any `FAILED` line or any missing file. Record each one in the chain of custody table.
- Doc: https://man7.org/linux/man-pages/man1/sha256sum.1.html (checked 2026-11-12)
- Local help: checked on macOS (`man shasum`). The `-c` option is listed. macOS 26 also includes `/sbin/sha256sum`. A local test showed that it reports a missing file only on standard error. It prints no `FAILED open or read` line for that file. `shasum -a 256 -c` prints that line, as GNU `sha256sum -c` does. Use `shasum -a 256` on macOS.

## Memory capture

Memory images hold passwords, keys, and session data. Each tool changes the host. Each entry is WRITE, SENSITIVE. A human decides whether to capture memory before any power change. Write the image to evidence storage, not to the suspect disk. Hash the image with HOST-26 after capture.

### HOST-31 Capture Linux memory with AVML

- Purpose: copy the physical memory of a Linux host to a file. Phase: evidence.
- Label: WRITE, SENSITIVE
- Permission: `root`. AVML reads `/dev/crash`, `/proc/kcore`, or `/dev/mem`. The doc page does not state that root is required.
- Command:

  ```bash
  <avml-binary-path> acquire <memory-image-path>
  ```

- Output: one image file in LiME format, about the size of the host memory. Look for: an error that names kernel lockdown. AVML cannot read memory when that feature is on. Use `--compress` to make a smaller file. Convert it back with `avml convert`.
- Side effect: writes a file as large as the host memory to `<memory-image-path>`. Use a path that does not exist yet, because AVML replaces a file at that path. It uses CPU and disk I/O on a host that may be under attack. It loads no kernel module. Run a trusted copy of the binary from read-only media.
- Rollback: follow safety rule 16 in `../SKILL.md` first. `rm -- '<memory-image-path>'`. This removes the image file only. Remove only a file that this run created. Delete a real evidence image only when the human approves.
- Approval: human approval required.
- Doc: https://github.com/microsoft/avml (checked 2026-11-12)
- Local help: AVML is for x86_64 Linux.

### HOST-32 Capture Linux memory with LiME

- Purpose: copy the physical memory of a Linux host with a kernel module. Phase: evidence.
- Label: WRITE, SENSITIVE
- Permission: `root`. The module must match the exact kernel version from `uname -r`.
- Command:

  ```bash
  lsmod
  insmod '<lime-module-path>' 'path=<memory-image-path>' format=lime timeout=0
  rmmod lime
  ```

  Pass each module parameter as a separate argument. The LiME README shows them in one quoted argument. The `insmod` of kmod quotes a value that holds a space, so LiME then gets no `format` and fails with an error.

  Run `lsmod` first. When its output lists `lime`, stop and tell the human, because another person loaded it. Run `rmmod lime` only after `insmod` succeeded in this run.

- Output: one image file in LiME format. The `path` value can also be `tcp:<port>` to send the image over the network. The `timeout=0` value disables the page timeout. The README says that with the default of 1000 ms, LiME skips the rest of a memory range when one page is slow. With `timeout=0`, the capture can take longer. Look for: a failed `insmod` message, which usually means a kernel mismatch.
- Completeness: a successful `insmod` and a hash do not prove that the image is complete. The LiME source stops the range loop after a header write error and skips the rest of a range after a page write error. It still returns success. Ask the human to compare the ranges in the image with the `System RAM` ranges in `/proc/iomem` on the host. When they differ, keep the image, label it incomplete, and ask the human about a new capture.
- Side effect: loads a kernel module and writes a file as large as the host memory to `<memory-image-path>`. Use a path that does not exist yet, because LiME can replace a file at that path. A module that is built on the suspect host can be altered. Build it on a trusted system.
- Rollback: follow safety rule 16 in `../SKILL.md` first. `rmmod lime` unloads the module. Run it only when this run loaded the module. The image file stays. Use `rm -- '<memory-image-path>'` only for a file that this run created, and only when the human approves.
- Approval: human approval required.
- Doc: https://github.com/504ensicsLabs/LiME (checked 2026-11-12). The README warns that the `digest` option overwrites more memory. This entry omits it. Hash the image with HOST-26 instead. LiME source: https://raw.githubusercontent.com/504ensicsLabs/LiME/master/src/main.c (checked 2026-11-12). kmod option parser: https://github.com/kmod-project/kmod/blob/master/tools/opt.c (checked 2026-11-12).

### macOS memory capture note

This file has no command for full memory capture on macOS. No public vendor source describes a tool for it. System Integrity Protection limits what the `root` user can do on a Mac. Apple describes it at https://support.apple.com/en-us/102149 (checked 2026-11-12). That page does not cover memory capture. A human must decide how to proceed. The options are a third-party tool, a different approach, or no memory capture. Collect HOST-01 to HOST-07 and HOST-15 to HOST-18 first.

## Disk capture

### HOST-33 Copy a Linux disk to an image with dd

- Purpose: make a bit-for-bit copy of a disk or partition for later analysis. Phase: evidence.
- Label: WRITE, SENSITIVE
- Permission: `root`. Write access to the evidence drive.
- Command:

  ```bash
  dd if=<source-device> of=<image-path> bs=64K conv=noerror,sync,excl status=progress
  ```

- Output: progress lines, then record counts and bytes copied. With `conv=noerror,sync`, dd continues after a read error and pads the bad block with zero bytes. The padding fills the whole input block, so one read error can replace up to 64 KiB with zeros. On a disk with read errors, ask the human about a second copy with a smaller `bs` value. Look for: read errors in the output. Record each one in the notes. Then hash the image with HOST-26.
- Side effect: writes a file as large as the source to `<image-path>` on the external evidence drive. With `excl`, dd fails when `<image-path>` already exists, so it cannot replace an earlier image. It adds read load on the source disk. Do not use `<image-path>` on the source disk. A mounted, live disk gives an inconsistent copy. When possible, use a write blocker or boot from read-only media.
- Rollback: follow safety rule 16 in `../SKILL.md` first. `rm -- '<image-path>'`. This removes the image file only. Remove only a file that this run created. Delete a real evidence image only when the human approves.
- Approval: human approval required.
- Doc: https://man7.org/linux/man-pages/man1/dd.1.html (checked 2026-11-12). The page documents GNU coreutils dd. It describes `excl` as "fail if the output file already exists".
- Local help: The macOS `dd` is the BSD version, so its man page differs.

In a cloud account, take a provider snapshot instead. See `commands-aws.md`.

### macOS disk capture note

This file has no command for disk capture on macOS. A human decides whether to engage a forensics firm. See `process.md` section 5.

## Chain of custody

This section has no command. Record each evidence item the moment you collect it. RFC 3227 asks for a record of where, when, and by whom the evidence was found, handled, and examined. It also asks for who held custody, how it was stored, and how each transfer happened. See https://www.rfc-editor.org/rfc/rfc3227 (checked 2026-11-12). NIST SP 800-86 gives general guidance on forensics in incident response at https://csrc.nist.gov/pubs/sp/800/86/final (checked 2026-11-12). The page that was read does not describe evidence handling.

Record these fields for each item:

1. Item ID.
2. Description.
3. Source host.
4. Collected by.
5. Collection time in UTC.
6. SHA-256 digest.
7. Storage location.
8. Each transfer, with who, when, and why.

Record the clock of the source host and its offset from a trusted clock. RFC 3227 asks for the clock drift. A human can read the host clock with `date -u`.

Item table:

| Item ID | Description | Source host | Collected by | Collected (UTC) | SHA-256 | Storage location |
| ------- | ----------- | ----------- | ------------ | --------------- | ------- | ---------------- |
|         |             |             |              |                 |         |                  |

Transfer table:

| Item ID | From (name) | To (name) | Time (UTC) | Reason | Method or shipping number | Digest checked (yes/no) |
| ------- | ----------- | --------- | ---------- | ------ | ------------------------- | ----------------------- |
|         |             |           |            |        |                           |                         |
