# slskd-port

This repository contains the FreeBSD port for [slskd](https://github.com/slskd/slskd).

## Port Overview
- Builds with .NET 10 (`lang/dotnet`) and uses the upstream `net10.0` target directly.
- `ReadyToRun` is disabled to avoid `crossgen2` crashes on FreeBSD; the result is still a self-contained single-file binary.
- Pulls the React WebUI from precompiled release to minimize build time/complexity.
- Create symlink for `libsqlite3.so` so .NET runtime can use SQLite.
- Customized `slskd.yml.sample`
  - Highlight important settings (volatile, dirs, auth)
  - Uncomment all sections
    - Easier reading (yaml syntax highlighting)
  - Remove the space after all comments
    - Now you need only remove # and modify setting ; keeps yaml valid
  - Override upstream defaults
    - log retention: 180 -> 30 days
	- webui ips: removed IPv6 for better compatability
	- diagnostic level: Info -> Warning

## Updating Port
- Bump **DISTVERSION** and **GH_TAGNAME**
- `make makesum` to pull dists and regenerate **distinfo**
- Regenerate **Makefile.nuget** from `work/slskd-*/src/slskd/obj/project.assets.json` after a successful restore/build
```bash
jq -r '.libraries | keys[] | select(contains("/")) | split("/") | "NUGET_DEPENDS+= \(.[0])=\(.[1])"' \
	work/slskd-*/src/slskd/obj/project.assets.json
```

## Building with poudriere
- Setup the overlay (assuming `/home/dev` is the root)
- Test & build
```bash
mkdir -p /home/dev/ports/net-p2p
ln -s /home/dev/slskd-port /home/dev/ports/net-p2p/slskd
poudriere ports -c -p overlay -m null -M /home/dev/ports
poudriere testport -j 14_3 -p main -O overlay net-p2p/slskd
poudriere bulk -C -j 14_3 -p main -O overlay net-p2p/slskd
```

## Local users/groups in poudriere
The port declares `USERS=slskd` and `GROUPS=slskd`. To keep these entries out of
the host's `passwd`/`group` databases, provide them only to the poudriere build
environment.

`/usr/local/etc/poudriere-UIDs`:
```
slskd:*:789:789::0:0:Soulseek Daemon:/var/db/slskd:/usr/sbin/nologin
```

`/usr/local/etc/poudriere-GIDs`:
```
slskd:*:789:
```

In the jail-specific make.conf (e.g. `/usr/local/etc/poudriere.d/<jail>-make.conf`):
```
UID_FILES= /etc/poudriere-UIDs /usr/ports/UIDs
GID_FILES= /etc/poudriere-GIDs /usr/ports/GIDs
```

Copy the files into the build jail from an executable poudriere hook
(`/usr/local/etc/poudriere.d/hooks/jail.sh`):
```sh
#!/bin/sh
[ "$1" = start ] || exit 0
install -m 0644 /usr/local/etc/poudriere-UIDs "${MASTERMNT}/etc/poudriere-UIDs"
install -m 0644 /usr/local/etc/poudriere-GIDs "${MASTERMNT}/etc/poudriere-GIDs"
```

## Notes
- Safe to ignore QA Warnings ; These libraries ARE required
```
Warning: you might not need LIB_DEPENDS on libicuuc.so
Warning: you might not need LIB_DEPENDS on libsqlite3.so
```
