######## INVOCATION EXAMPLE ########
# cd; rm -rf /tmp/mybuild; mkdir /tmp/mybuild; cd /tmp/mybuild
# cmake ~/devel/agl/platform-runtime-tools/ -DCMAKE_INSTALL_PREFIX=install; make install; tree -p install
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
set (SYSTEM_UNIT_DIR ${CMAKE_INSTALL_FULL_LIBDIR}/systemd/system CACHE STRING "Path to systemd system unit files")

# location for scripts loaded by pr-detect or pr-customize
set (SCRIPTS_DIR ${CMAKE_INSTALL_FULL_LIBEXECDIR}/${PROJECT_NAME} CACHE STRING "Path to install scriptlets")

# detection results dir
set (DETECTION_OUTPUT_DIR ${CMAKE_INSTALL_FULL_SYSCONFDIR}/platform-info CACHE STRING "Runtime folder where detection results will be stored")

# prefix (mostly for pr-registry)
set (REGISTRY_PREFIX agl CACHE STRING "Prefix used in registry entries (prefix.section.name=value)")


############### IMPORTANT NOTE ###############
#
# files with extension '.in' are considered as templates and will be processed accordingly
# i.e. each @xxxx@ string will be replaced by the corresponding variable value
#
##############################################
foreach(subdir bin etc services scriptlets)
	# get all files in "source" subdirs
	file(GLOB_RECURSE files LIST_DIRECTORIES false "${subdir}/*")
	foreach(srcfile ${files})
		# compute relative path to source dir
		file(RELATIVE_PATH dstfile ${CMAKE_CURRENT_SOURCE_DIR} ${srcfile})
		if(srcfile MATCHES "\\.in$")
			# will process templates in "GNU" mode (=replacing @xxxx@ by vars)
			string(REGEX REPLACE "\\.[^.]*$" "" dstfile "${dstfile}")
			set(templateopts "@ONLY")
		else()
			# no templating: simple copy
			set(templateopts "COPYONLY")
		endif()
		#message("Processing file: ${srcfile} => ${dstfile} (${templateopts})")
		configure_file(${srcfile} ${CMAKE_CURRENT_BINARY_DIR}/${dstfile} ${templateopts})
	endforeach()
endforeach()

####### install 'binaries' ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/bin/*)
install (
    PROGRAMS ${files}
	DESTINATION ${CMAKE_INSTALL_FULL_BINDIR}/
)

####### install config files/folders ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/etc/*)
install (
	FILES ${files}
	DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/${PROJECT_NAME}/
)
install(DIRECTORY DESTINATION ${CMAKE_INSTALL_FULL_SYSCONFDIR}/${PROJECT_NAME}/registry.conf.d)

####### install systemd services ######
file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/services/*)
install (
	FILES ${files}
	DESTINATION ${SYSTEM_UNIT_DIR}
)

####### install scripts ######
# scripts are split in two parts:
# - detection scripts (for various steps: core, devices, ...) run by pr-detect
# - customization scripts run by pr-customize (not provided here, so installed as an empty folder)

foreach(step core devices)
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scriptlets/customize/${step})
endforeach()

foreach(subdir detect customize)
	install (
		DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scriptlets/${subdir}
		DESTINATION ${SCRIPTS_DIR}
		FILE_PERMISSIONS OWNER_READ GROUP_READ
		DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
	)
endforeach()


