######## INVOCATION EXAMPLE ########
# cd; rm -rf /tmp/mybuild; mkdir /tmp/mybuild; cd /tmp/mybuild
# cmake ~/devel/agl/platform-runtime-tools/ -DCMAKE_INSTALL_PREFIX=install -DUNITDIR_SYSTEM=lib/systemd/system; make install; tree -p install
####################################

# define all CMAKE_INSTALL_XXXX vars
include(GNUInstallDirs)

cmake_minimum_required(VERSION 3.5)

project (pr-tools NONE)

# version handling
set (pr-tools_VERSION_MAJOR 1)
set (pr-tools_VERSION_MINOR 0)
set (pr-tools_VERSION_PATCH 0)
set (pr-tools_VERSION "${pr-tools_VERSION_MAJOR}.${pr-tools_VERSION_MINOR}.${pr-tools_VERSION_PATCH}")

# systemd location for system services
set (UNITDIR_SYSTEM ${CMAKE_INSTALL_LIBDIR}/systemd/system CACHE STRING "Path to systemd system unit files")

# prefix (mostly for pr-registry)
set (REGISTRY_PREFIX agl CACHE STRING "Prefix used in registry entries (prefix.section.name=value)")

############### IMPORTANT NOTE ###############
#
# files with extension '.in' are considered as templates and will be processed accordingly
# i.e. each @xxxx@ string will be replaced by the corresponding variable value
#
##############################################
foreach(subdir bin etc services scriptlets)
	file(GLOB_RECURSE files LIST_DIRECTORIES false "${subdir}/*")
	foreach(srcfile ${files})
		get_filename_component(dstfile ${srcfile} NAME)
		if(srcfile MATCHES "\\.in$")
			string(REGEX REPLACE "\\.[^.]*$" "" dstfile "${dstfile}")
			#message("Template file: ${srcfile} => ${dstfile}")
			configure_file(${srcfile} ${CMAKE_CURRENT_BINARY_DIR}/${subdir}/${dstfile} @ONLY)
		else()
			#message("Non template file: ${srcfile} => ${dstfile}")
			configure_file(${srcfile} ${CMAKE_CURRENT_BINARY_DIR}/${subdir}/${dstfile} COPYONLY)
		endif()
	endforeach()
endforeach()

####### install 'binaries' ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/bin/*)
install (
    PROGRAMS ${files}
	DESTINATION ${CMAKE_INSTALL_BINDIR}/
)

####### install config files/folders ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/etc/*)
install (
	FILES ${files}
	DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/${PROJECT_NAME}/
)

####### install systemd services ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/services/*)
install (
	FILES ${files}
	DESTINATION ${UNITDIR_SYSTEM}
)

####### install scriptlets (libexec) ######
install (
	DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scriptlets
	DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/${PROJECT_NAME}
	FILE_PERMISSIONS OWNER_READ GROUP_READ
	DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
	FILES_MATCHING PATTERN "*"
)

