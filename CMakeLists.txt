cmake_minimum_required(VERSION 3.5)

project (pr-tools NONE)

set (pr-tools_VERSION_MAJOR 1)
set (pr-tools_VERSION_MINOR 0)
set (pr-tools_VERSION_PATCH 0)
set (pr-tools_VERSION "${pr-tools_VERSION_MAJOR}.${pr-tools_VERSION_MINOR}.${pr-tools_VERSION_PATCH}")

foreach(subdir bin etc)
	file(GLOB files "${subdir}/*")
	foreach(srcfile ${files})
		get_filename_component(dstfile ${srcfile} NAME)
		configure_file(${srcfile} ${PROJECT_BINARY_DIR}/${subdir}/${dstfile})
	endforeach()

	install (
		DIRECTORY ${PROJECT_BINARY_DIR}/${subdir}
		DESTINATION ${CMAKE_INSTALL_PREFIX}
		FILES_MATCHING PATTERN "*"
	)
endforeach()


