cmake_minimum_required(VERSION 3.10)
project(tag-designs-docs-site LANGUAGES NONE)

# find the files

file(GLOB SRC_FILES ${PROJECT_SOURCE_DIR}/tikz/*.tex)

# create output directory

set(image-out-directory "${CMAKE_CURRENT_SOURCE_DIR}/static/images-svg")
file(MAKE_DIRECTORY ${image-out-directory})

add_custom_target(images-svg)

foreach(f ${SRC_FILES})
  # process names

  get_filename_component(fname ${f} NAME_WLE)
  set(out-files "${fname}.pdf" "${fname}.svg")

  # generate targets

  add_custom_command(
    OUTPUT "${fname}.pdf"
    COMMAND pdflatex -output-directory="${CMAKE_CURRENT_BINARY_DIR}"
            -interaction=batchmode "${f}"
    #COMMAND cmake -E copy_if_different "${fname}.pdf" "${image-out-directory}"
    BYPRODUCTS "${CMAKE_CURRENT_BINARY_DIR}/${fname}.log"
               "${CMAKE_CURRENT_BINARY_DIR}/${fname}.aux"
    DEPENDS ${f})

  add_custom_command(
    OUTPUT "${fname}.svg"
    COMMAND pdf2svg "${fname}.pdf" "${fname}.svg"
    COMMAND cmake -E copy_if_different "${fname}.svg" "${image-out-directory}"
    DEPENDS "${fname}.pdf")

  add_custom_target("${fname}-tikz" DEPENDS ${fname}.svg)
  add_dependencies(images-svg "${fname}-tikz")
endforeach()

set(HUGO_BASEURL "/" CACHE STRING "Base URL passed to Hugo when building the docs target")

if(WIN32)
  set(HUGO_PATH "${CMAKE_CURRENT_SOURCE_DIR}/node_modules/.bin;$ENV{PATH}")
else()
  set(HUGO_PATH "${CMAKE_CURRENT_SOURCE_DIR}/node_modules/.bin:$ENV{PATH}")
endif()
set(POSTCSS_BIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/node_modules/.bin")

add_custom_target(docs
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${HUGO_PATH}"
          "${CMAKE_COMMAND}" -DPOSTCSS_BIN_DIR="${POSTCSS_BIN_DIR}"
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CheckPostCSS.cmake"
  COMMAND "${CMAKE_COMMAND}" -E env "PATH=${HUGO_PATH}"
          hugo -d "${CMAKE_CURRENT_BINARY_DIR}/public/"
               -s "${CMAKE_CURRENT_SOURCE_DIR}"
               -b "${HUGO_BASEURL}"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

find_program(RSYNC_EXECUTABLE rsync)
set(GH_PAGES_DIR "${CMAKE_BINARY_DIR}/../ab-paper-gh-pages" CACHE PATH
    "Local GitHub Pages checkout used by the sync-gh-pages target")

if(RSYNC_EXECUTABLE)
  add_custom_target(
    sync-gh-pages
    COMMAND "${RSYNC_EXECUTABLE}" -rcv --delete --exclude=.git
            "${CMAKE_CURRENT_BINARY_DIR}/public/"
            "${GH_PAGES_DIR}"
    DEPENDS docs)
else()
  message(STATUS "rsync not found; sync-gh-pages target will not be available")
endif()
