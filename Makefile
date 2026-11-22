PORTNAME=		slskd
DISTVERSION=	0.26.2
PORTREVISION=	1
CATEGORIES=		net-p2p

MAINTAINER=		squared.pusher@gmail.com
COMMENT=		Modern client-server application for the Soulseek file sharing network
WWW=			https://github.com/slskd/slskd

LICENSE=		AGPLv3
LICENSE_FILE=	${WRKSRC}/LICENSE

LIB_DEPENDS=	libbrotlidec.so:archivers/brotli \
				libbrotlienc.so:archivers/brotli \
				libgssapi_krb5.so:security/krb5 \
				libinotify.so:devel/libinotify \
				libunwind.so:devel/libunwind \
				libicuuc.so:devel/icu
BUILD_DEPENDS=	dotnet>=10:lang/dotnet

USES=			sqlite:3 ssl
USE_RC_SUBR=	slskd

EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX} \
				slskd-${DISTVERSION}-linux-x64.zip

SUB_FILES=		pkg-message

USE_GITHUB=		yes
GH_ACCOUNT=		slskd
GH_PROJECT=		slskd
GH_TAGNAME=		0.26.2

USERS=			slskd
GROUPS=			slskd

DOTNET_ARCH=	${ARCH:S/amd64/x64/:S/aarch64/arm64/}
DOTNET_OSREL=	${OSREL:R}

MASTER_SITES+=	https://github.com/slskd/slskd/releases/download/${DISTVERSION}/:webui
DISTFILES+=		slskd-${DISTVERSION}-linux-x64.zip:webui

.include "Makefile.nuget"

.for depend in ${NUGET_DEPENDS}
MASTER_SITES+=	https://www.nuget.org/api/v2/package/${depend:C/=.*$//:tl}/${depend:C/^.*=//:tl}/?dummy=/:nuget_${depend:C/[.+=-]//g}
DISTFILES+=		${depend:C/=.*$//:tl}.${depend:C/^.*=//:tl}.nupkg:nuget_${depend:C/[.+=-]//g}
.endfor

post-extract:
	@${MKDIR} ${WRKDIR}/nuget
	@${ECHO_CMD} "Setting up local NuGet cache..."
.for depend in ${NUGET_DEPENDS}
	@${CP} ${DISTDIR}/${depend:C/=.*$//:tl}.${depend:C/^.*=//:tl}.nupkg ${WRKDIR}/nuget/
.endfor

do-build:
	cd ${WRKSRC}/src/slskd && \
		${SETENV} ${MAKE_ENV} dotnet restore slskd.csproj \
			--source ${WRKDIR}/nuget \
			--packages ${WRKDIR}/packages \
			--runtime freebsd.${DOTNET_OSREL}-${DOTNET_ARCH} && \
		${SETENV} ${MAKE_ENV} dotnet publish slskd.csproj \
			-c Release \
			--runtime freebsd.${DOTNET_OSREL}-${DOTNET_ARCH} \
			--framework net10.0 \
			-p:ReadyToRun=false \
			-p:PublishSingleFile=true \
			-p:IncludeNativeLibrariesForSelfExtract=true \
			-p:Version=${DISTVERSION} \
			--self-contained \
			--no-restore \
			-o ${WRKDIR}/publish

do-install:
	@${MKDIR} ${STAGEDIR}${DATADIR}
	${INSTALL_SCRIPT} ${WRKDIR}/publish/slskd ${STAGEDIR}${DATADIR}
	cd ${WRKDIR}/wwwroot && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/wwwroot
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc
	${INSTALL_DATA} ${FILESDIR}/slskd.yml.sample \
		${STAGEDIR}${PREFIX}/etc/slskd.yml.sample
	${LN} -sf ../../lib/libsqlite3.so ${STAGEDIR}${DATADIR}/libe_sqlite3.so

post-install:
	@${ECHO_CMD} "@sample etc/slskd.yml.sample" > ${TMPPLIST}
	@${ECHO_CMD} "${DATADIR_REL}/libe_sqlite3.so" >> ${TMPPLIST}
	@cd ${STAGEDIR}${DATADIR} && ${FIND} . -type f | ${SED} 's|^.|${DATADIR_REL}|' | ${SORT} >> ${TMPPLIST}
	@cd ${STAGEDIR}${DATADIR} && ${FIND} * -type d | ${SED} 's|^|@dir ${DATADIR_REL}/|' | ${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>
