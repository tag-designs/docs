set(postcss_candidates
  "${POSTCSS_BIN_DIR}/postcss"
  "${POSTCSS_BIN_DIR}/postcss.cmd"
  "${POSTCSS_BIN_DIR}/postcss.ps1")

set(postcss_found FALSE)
foreach(candidate IN LISTS postcss_candidates)
  if(EXISTS "${candidate}")
    set(postcss_found TRUE)
    break()
  endif()
endforeach()

if(NOT postcss_found)
  message(FATAL_ERROR
    "PostCSS was not found in ${POSTCSS_BIN_DIR}. "
    "Run `npm ci` from the docs directory before building the CMake docs target.")
endif()

find_program(HUGO_EXECUTABLE hugo)
if(NOT HUGO_EXECUTABLE)
  message(FATAL_ERROR
    "Hugo was not found on PATH. Install Hugo Extended before building the "
    "CMake docs target.")
endif()

execute_process(
  COMMAND "${HUGO_EXECUTABLE}" version
  OUTPUT_VARIABLE hugo_version_output
  ERROR_VARIABLE hugo_version_error
  RESULT_VARIABLE hugo_version_result
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE)

if(NOT hugo_version_result EQUAL 0)
  message(FATAL_ERROR
    "Could not determine the Hugo version from ${HUGO_EXECUTABLE}: "
    "${hugo_version_error}")
endif()

if(hugo_version_output MATCHES "v([0-9]+)\\.([0-9]+)\\.([0-9]+)")
  set(hugo_major "${CMAKE_MATCH_1}")
  set(hugo_minor "${CMAKE_MATCH_2}")
  set(hugo_patch "${CMAKE_MATCH_3}")
  set(hugo_version_short "v${hugo_major}.${hugo_minor}.${hugo_patch}")

  if(hugo_major GREATER 0 OR hugo_minor GREATER_EQUAL 161)
    find_program(NODE_EXECUTABLE node)
    if(NOT NODE_EXECUTABLE)
      message(FATAL_ERROR
        "Node.js was not found on PATH. Hugo ${hugo_version_short} uses "
        "Node's permission flags when running PostCSS, so install Node.js 22 "
        "LTS or newer.")
    endif()

    execute_process(
      COMMAND "${NODE_EXECUTABLE}" --version
      OUTPUT_VARIABLE node_version_output
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
      COMMAND "${NODE_EXECUTABLE}" --permission -e "process.exit(0)"
      OUTPUT_QUIET
      ERROR_QUIET
      RESULT_VARIABLE node_permission_result)

    if(NOT node_permission_result EQUAL 0)
      message(FATAL_ERROR
        "The Node.js executable on PATH (${NODE_EXECUTABLE} "
        "${node_version_output}) does not support the --permission flag used "
        "by Hugo ${hugo_version_short} for PostCSS. Install Node.js 22 LTS "
        "or newer, or build with Hugo 0.160.x.")
    endif()
  endif()
endif()
