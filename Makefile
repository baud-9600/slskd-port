PORTNAME=	slskd
DISTVERSION=	0.25.1
CATEGORIES=	net-p2p

MAINTAINER=	squared.pusher@gmail.com
COMMENT=	A modern client-server application for the Soulseek file sharing network.
WWW=		https://github.com/slskd/slskd

LICENSE=	AGPLv3
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	dotnet>=9:lang/dotnet
LIB_DEPENDS=	libsqlite3.so:databases/sqlite3
# RUN_DEPENDS=	uknown ## NEEDED?

# USES=	uknown ## NEEDED?
USE_GITHUB=	yes
GH_ACCOUNT=	slskd
GH_PROJECT=	slskd
USE_RC_SUBR=	slskd

# USERS=		slskd ## TODO
# GROUPS=		slskd ## TODO

DOTNET_ARCH=	${ARCH:S/amd64/x64/:S/aarch64/arm64/}
DOTNET_OSREL=	${OSREL:R}
# DOTNET_CMD=	${SETENV} HOME=${WRKDIR} ${LOCALBASE}/bin/dotnet ## NEEDED?

EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

.include "Makefile.nuget"

.for depend in ${NUGET_DEPENDS}
DISTFILES+=	${depend:C/=.*$//:tl}.${depend:C/^.*=//:tl}.nupkg:nuget_${depend:C/[.+=-]//g}
MASTER_SITES+=	https://www.nuget.org/api/v2/package/${depend:C/=.*$//:tl}/${depend:C/^.*=//:tl}/?dummy=/:nuget_${depend:C/[.+=-]//g}
.endfor

post-patch:
	@${REINPLACE_CMD} -e 's|<TargetFramework>net10.0</TargetFramework>|<TargetFramework>net9.0</TargetFramework>|' \
		${WRKSRC}/src/slskd/slskd.csproj
	@${REINPLACE_CMD} \
		-e 's|^# web:|web:|' \
		-e 's|^#   ip_address: 0.0.0.0,\[::\]|  ip_address: 0.0.0.0|' \
		-e 's|^#   https:|  https:|' \
		-e 's|^#     ip_address: 0.0.0.0,\[::\]|    ip_address: 0.0.0.0|' \
		${WRKSRC}/config/slskd.example.yml

post-extract:
	@${MKDIR} ${WRKDIR}/nuget
.for depend in ${NUGET_DEPENDS}
	@${CP} ${DISTDIR}/${depend:C/=.*$//:tl}.${depend:C/^.*=//:tl}.nupkg ${WRKDIR}/nuget/
.endfor

do-build:
	cd ${WRKSRC}/src/slskd && \
	${SETENV} HOME=${WRKDIR} dotnet restore slskd.csproj --source ${WRKDIR}/nuget --packages ${WRKDIR}/packages && \
	${SETENV} HOME=${WRKDIR} dotnet publish -c Release --runtime freebsd.${DOTNET_OSREL}-${DOTNET_ARCH} --framework net9.0 -p:ReadyToRun=true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:Version=${DISTVERSION} --self-contained -o ${WRKDIR}/publish

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/slskd
	cd ${WRKDIR}/publish && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/share/slskd
	@${RM} -r \
		${STAGEDIR}${PREFIX}/share/slskd/slskd.pdb \
		${STAGEDIR}${PREFIX}/share/slskd/etc \
		${STAGEDIR}${PREFIX}/share/slskd/LICENSE \
		${STAGEDIR}${PREFIX}/share/slskd/config \
		${STAGEDIR}${PREFIX}/share/slskd/wwwroot

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc
	${INSTALL_DATA} ${WRKSRC}/config/slskd.example.yml \
		${STAGEDIR}${PREFIX}/etc/slskd.yml.sample
	${CHMOD} +x ${STAGEDIR}${PREFIX}/share/slskd/slskd
	${RLN} ${LOCALBASE}/lib/libsqlite3.so ${STAGEDIR}${PREFIX}/share/slskd/libe_sqlite3.so

.include <bsd.port.mk>
