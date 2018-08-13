// Specify parameters to configure which repo and branch to build
properties([parameters([
             string(defaultValue: 'llvm-mirror/llvm', description: 'LLVM Github Repo Name', name: 'LLVMRepoName'),
             string(defaultValue: 'master', description: 'LLVM Branch Name', name: 'LLVMBranchName'),
             string(defaultValue: 'llvm-mirror/clang', description: 'Clang Github Repo Name', name: 'ClangRepoName'),
             string(defaultValue: 'master', description: 'Clang Branch Name', name: 'ClangBranchName'),
])])

// Set job name based on repo and branch names
String JobName = 'llvm:' + params.LLVMRepoName + ':' + params.LLVMBranchName + ',clang:' + params.ClangRepoName + ':' + params.ClangBranchName
currentBuild.displayName = JobName

node ('buildnode') {
  // Cleanup previous build and log files
  stage('Cleanup') {
    sh '''#!/bin/sh
          (cd riscv-gnu-toolchain && git clean -fxd)
          (cd riscv-llvm-testing && git clean -fxd)
          rm -rf llvm/build install
          rm -rf *.log'''
  }

  // Checkout git repositories
  stage('Checkout') {
      // This repository holds patches to apply to toolchain sources
      git url: 'https://github.com/embecosm/riscv-llvm-jenkins.git', branch: 'master'
      // GNU components
      dir('riscv-gnu-toolchain') {
        checkout([$class: 'GitSCM',
                  branches: [[name: '*/master']],
                  doGenerateSubmoduleConfigurations: false,
                  extensions: [[$class: 'SubmoduleOption',
                                disableSubmodules: false,
                                parentCredentials: false,
                                recursiveSubmodules: true,
                                reference: '',
                                trackingSubmodules: false,
                                timeout: 30],
                               [$class: 'CloneOption',
                                timeout: 30]],
                  submoduleCfg: [],
                  userRemoteConfigs: [[url: 'https://github.com/riscv/riscv-gnu-toolchain.git']]]
        )
      }
      // LLVM components
      dir('llvm/llvm') {
        git url: 'https://github.com/' + '${LLVMRepoName}' + '.git', branch: '${LLVMBranchName}'
        sh 'cd tools && ln -sf ../../clang'
      }
      dir('llvm/clang') {
        git url: 'https://github.com/' + '${ClangRepoName}' + '.git', branch: '${ClangBranchName}'
      }
      // Test components
      dir('gcc-tests') {
        git url: 'https://github.com/embecosm/gcc-for-llvm-testing.git', branch: 'llvm-testing'
      }
  }

  // Build various components
  stage('Build GNU Tools') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('riscv-gnu-toolchain') {
            sh './configure --prefix=${WORKSPACE}/install --with-arch=rv32gc --with-abi=ilp32 > ../build-gnu.log 2>&1'
            sh 'make -j$(nproc) >> ../build-gnu.log 2>&1'
          }
        }
      }
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'build-gnu.log'
      }
    }
  }
  stage('Build LLVM Tools') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('llvm/build') {
            sh '''cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS=ON \
                        -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/install \
                        -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RISCV  \
                        -DLLVM_BINUTILS_INCDIR=/${WORKSPACE}/riscv-gnu-toolchain/riscv-binutils/include \
                        -DLLVM_ENABLE_THREADS=OFF \
                        -G Ninja ../llvm > ../../build-llvm.log 2>&1'''
            sh 'ninja install >> ../../build-llvm.log 2>&1'
          }
        }
        dir('install/bin') {
          sh 'ln -sf clang riscv32-unknown-elf-clang'
        }
      }
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'build-llvm.log'
      }
    }
  }

  // Run Tests
  stage('GCC Regression (GCC)') {
    timeout(120) {
      try {
        // Because Ubuntu 18.04 uses a newer glibc, we need to pull a couple of upstream patches
        dir('riscv-gnu-toolchain/riscv-qemu') {
          sh 'git am ${WORKSPACE}/patches/qemu-memfd.patch'
          sh 'git am ${WORKSPACE}/patches/qemu-ucontext.patch'
        }
        docker.image('embecosm/buildenv').inside {
          dir('riscv-gnu-toolchain') {
            sh '''PATH=${WORKSPACE}/install/bin:$PATH
                  make -j$(nproc) check-gcc-newlib > ../check-gcc.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-gcc.log, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/gcc/gcc.sum, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/gcc/gcc.log'
      }
    }
  }
  stage('LLVM Checks') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('llvm/build') {
            sh '''ninja check-all > ../../check-clang.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-clang.log'
      }
    }
  }
  stage('GCC Regression (Clang)') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('riscv-llvm-testing') {
            sh '''PATH=${WORKSPACE}/install/bin:$PATH
                 ./run-tests.py > ../check-clang-gcc.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-clang-gcc.log, riscv-llvm-testing/test-output/gcc.log, riscv-llvm-testing/test-output/gcc.sum'
      }
    }
  }
}
