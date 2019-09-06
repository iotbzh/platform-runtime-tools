include(GNUInstallDirs)

cmake_minimum_required(VERSION 3.5)

project (pr-tools NONE)

set (pr-tools_VERSION_MAJOR 1)
set (pr-tools_VERSION_MINOR 0)
set (pr-tools_VERSION_PATCH 0)
set (pr-tools_VERSION "${pr-tools_VERSION_MAJOR}.${pr-tools_VERSION_MINOR}.${pr-tools_VERSION_PATCH}")

set (UNITDIR_SYSTEM ${CMAKE_INSTALL_LIBDIR}/systemd/system CACHE STRING "Path to systemd system unit files")

foreach(subdir bin etc services scriptlets)
	file(GLOB_RECURSE files LIST_DIRECTORIES false "${subdir}/*")
	foreach(srcfile ${files})
		get_filename_component(dstfile ${srcfile} NAME)
		configure_file(${srcfile} ${CMAKE_CURRENT_BINARY_DIR}/${subdir}/${dstfile})
	endforeach()
endforeach()

file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/bin/*)
install (
    PROGRAMS ${files}
	DESTINATION ${CMAKE_INSTALL_BINDIR}/
)

file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/etc/*)
install (
	FILES ${files}
	DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/${PROJECT_NAME}/
)

file(GLOB_RECURSE files LIST_DIRECTORIES false ${CMAKE_CURRENT_BINARY_DIR}/services/*)
install (
	FILES ${files}
	DESTINATION ${UNITDIR_SYSTEM}
)

install (
	DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scriptlets
	DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/${PROJECT_NAME}
	FILES_MATCHING PATTERN "*"
)




