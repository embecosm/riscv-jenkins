node ('buildnode') {
  // Cleanup previous build and log files
  stage('Cleanup') {
    sh '''#!/bin/sh
          (cd llvm-testing && git clean -fxd)
          rm -rf llvm/build install
          rm -rf *.log'''
  }

  // Checkout git repositories
  stage('Checkout') {
      // This repository holds patches to apply to toolchain sources
      dir('llvm-testing') {
        git url: 'https://github.com/embecosm/riscv-llvm-jenkins.git', branch: 'native'
      }
      // LLVM components
      dir('llvm/llvm') {
        git url: 'https://github.com/llvm-mirror/llvm.git', branch: 'master'
        sh 'cd tools && ln -sf ../../clang'
      }
      dir('llvm/clang') {
        git url: 'https://github.com/llvm-mirror/clang.git', branch: 'master'
      }
      // Test components
      dir('gcc-tests') {
        git url: 'https://github.com/embecosm/gcc-for-llvm-testing.git', branch: 'llvm-testing'
      }
  }

  // Build various components
  stage('Build LLVM Tools') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('llvm/build') {
            sh '''cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_SHARED_LIBS=ON \
                        -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/install \
                        -DLLVM_ENABLE_THREADS=OFF \
                        -DLLVM_BINUTILS_INCDIR=/usr/lib/gcc/x86_64-linux-gnu/7/plugin/include \
                        -G Ninja ../llvm > ../../build-llvm.log 2>&1'''
            sh 'ninja install >> ../../build-llvm.log 2>&1'
          }
        }
      }
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'build-llvm.log'
      }
    }
  }

  // Run Tests
  stage('LLVM Tests') {
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
          dir('llvm-testing') {
            sh '''PATH=${WORKSPACE}/install/bin:$PATH
                 ./run-tests.py > ../check-clang-gcc.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-clang-gcc.log, llvm-testing/test-output/gcc.log, llvm-testing/test-output/gcc.sum'
      }
    }
  }
}
