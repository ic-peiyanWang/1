import os
from ccorp.ruamel.yaml.include import YAML
from conans import ConanFile, CMake, tools

class PnCPlannerConan(ConanFile):
    name = "planner_cyber"
    generators ='cmake_find_package'
    settings = "compiler", "build_type", "arch", "platform", "os"
    exports = ["conan/kuma.yml"]
    scm = {
     "type": "git",
     "url": "auto",
     "revision": "disable",
     "password": os.environ.get("CONAN_TOKEN", None)
    }
    def requirements(self):
        yaml = YAML(typ=['safe'], pure=True)
        with open(os.path.join(self.recipe_folder, "conan/kuma.yml"), encoding='utf-8') as fr:
            self.require_dict = yaml.load(fr)
            
        if 'common' in self.require_dict.keys():
            for each in self.require_dict['common']:
                self.requires(self.require_dict['common'][each])
        
        # platform = ["orin", "x86_64"]
        platform = str(self.settings.platform)
        if platform in self.require_dict.keys():
            for each in self.require_dict[platform].keys():
                self.requires(self.require_dict[platform][each])

    def build(self):
        cmake = CMake(self, parallel=True)
        cmake.definitions["USE_CONAN"] = "ON"
        if os.environ.get('NO_UT','0') == "1":
            cmake.definitions["NO_UT"] = "ON"
        else:
            cmake.definitions["NO_UT"] = "OFF"  
        # cmake.definitions["CMAKE_CXX_COMPILER_LAUNCHER"] = "ccache"
        # os.environ['CONAN_CPU_COUNT'] = "8"
        if self.settings.platform == "x86_64":
            os.environ['MAZU_ARCH'] = "x86"
            cmake.definitions["MAZU_ARCH"] = "x86_64"
        else:
            os.environ['MAZU_ARCH'] = "aarch64"
            cmake.definitions["MAZU_ARCH"] = "aarch64"
        print("MAZU_ARCH: ", os.environ.get("MAZU_ARCH"))

        cmake.configure(source_folder="./")
        cmake.build()

    def package(self):
        cmake = CMake(self, parallel=True)
        cmake.install()
        # self.copy("*", src="package", dst="", keep_path=True)
        self.copy("*.h", dst="include", src="./", keep_path=True)
        self.copy("lib/*.so", dst="lib", keep_path=False)

    def package_info(self):
        self.cpp_info.libdirs = ["lib"]   
        self.cpp_info.libs = tools.collect_libs(self)
        self.cpp_info.includedirs = ["include"]