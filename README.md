# slskd-port

This repository contains the FreeBSD port for [slskd](https://github.com/slskd/slskd).

## Port Overview
- TargetFramework changed from "net10.0" to "net9.0"
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
- `make makesum` to pull dists
- Update **Makefile.nuget** after a `make`
```bash
cat work/slskd-*/src/slskd/obj/project.assets.json | \
	jq -r '.libraries | keys[] | select(contains("/")) | split("/") | "NUGET_DEPENDS+= \(.[0])=\(.[1])"'
```
- Build with `poudriere`
```bash
poudriere testport -j 14_3 -p main -O . net-p2p/slskd
poudriere bulk -C -j 14_3 -p main -O . net-p2p/slskd
```

## Notes
- Safe to ignore QA Warnings ; These libraries ARE required
```
Warning: you might not need LIB_DEPENDS on libicuuc.so
Warning: you might not need LIB_DEPENDS on libsqlite3.so
```
