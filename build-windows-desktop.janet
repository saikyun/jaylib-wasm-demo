(def build-dir "build")

(def preload-dir "cross")
(def lib-dir (string preload-dir "\\jpm_tree\\lib"))

###########################################################################

(def start (os/clock))

(prinf "\n[ensuring existence of build directory: %p]..." build-dir)
(try
  (os/mkdir build-dir)
  ([e]
    (eprintf "<<problem with mkdir for: %p>>" build-dir)
    (os/exit 1)))

(printf "\n[preparing amalgamated janet.c and related]...")
(let [old-dir (os/cwd)]
  (try
    (os/cd "janet")
    ([e]
      (eprintf "<<failed to cd to janet directory>>")
      (os/exit 1)))
  (try
    (os/execute ["build_win.bat" "clean"] :px)
    ([e]
      (eprintf "<<problem with cleaning for janet>>")
      (os/exit 1)))
  (try
    (os/execute ["build_win.bat"] :px)
    ([e]
      (eprintf "<<problem building janet>>")
      (os/exit 1)))
  (try
    (os/cd old-dir)
    ([e]
      (eprintf "<<problem restoring current directory>>")
      (os/exit 1))))
#
(printf "\n[preparing object files for raylib.lib]...")
(def commands
  [["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rshapes.o"
    "freja-jaylib/raylib/src/rshapes.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rtextures.o"
    "freja-jaylib/raylib/src/rtextures.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/raudio.o"
    "freja-jaylib/raylib/src/raudio.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rglfw.o"
    "freja-jaylib/raylib/src/rglfw.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rcore.o"
    "freja-jaylib/raylib/src/rcore.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rmodels.o"
    "freja-jaylib/raylib/src/rmodels.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/rtext.o"
    "freja-jaylib/raylib/src/rtext.c"]
   ["cl.exe"
    "-D_POSIX_C_SOURCE=200809L"
    "-DPLATFORM_DESKTOP"
    "/c"
    "/nologo"
    "/MD"
    "-Ifreja-jaylib/raylib/src"
    "-Ifreja-jaylib/raylib/src/external/glfw/include"
    "-O2"
    "/LD"
    "/Fobuild/utils.o"
    "freja-jaylib/raylib/src/utils.c"]])
(each cmd commands
  (try
    (os/execute cmd :px)
    ([e]
      (eprintf "<<problem building object file: %p>>" cmd)
      (os/exit 1))))

(printf "\n[creating raylib.lib]...")
(try
  (os/execute ["lib.exe"
               "/nologo"
               "/out:build/raylib.lib"
               "build/rcore.o"
               "build/rmodels.o"
               "build/raudio.o"
               "build/rglfw.o"
               "build/rshapes.o"
               "build/rtext.o"
               "build/rtextures.o"
               "build/utils.o"
               ]
              :px)
  ([e]
    (eprintf "<<problem compiling: %p>>" e)
    (os/exit 1)))

(printf "\n[preparing freja-jaylib.janet shim]...")
(try
  (os/execute ["janet"
               "make-freja-jaylib-janet-shim.janet"
               "freja-jaylib/src"
               (string lib-dir "/freja-jaylib.janet")] :px)
  ([e]
    (eprintf "<<problem creating freja-jaylib.janet shim>>")
    (os/exit 1)))

(printf "\n[compiling final product]...")
(try
  (os/execute ["cl.exe"
               "main.c"
               "janet/build/c/janet.c"
               "-Ijanet/src/include"
               "-Ijanet/src/conf"
               "-Ifreja-jaylib/raylib/src"
               #"-Ifreja-jaylib/src"
               "/MD"
               #"/link" "/DEBUG"
               "build/raylib.lib"
               "user32.lib"
               "opengl32.lib"
               "gdi32.lib"
               "winmm.lib"
               "shell32.lib"
               (string "/Fe:" preload-dir "\\main.exe")
               ]
              :px)
  ([e]
    (eprintf "<<problem compiling: %p>>" e)
    (os/exit 1)))
(print)

(def end (os/clock))

(printf "Completed in %p seconds" (- end start))

