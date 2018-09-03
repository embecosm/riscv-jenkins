node ('buildnode') {
  // Cleanup previous build and log files
  stage('Cleanup') {
    sh '''#!/bin/sh
          (cd riscv-gnu-toolchain && git clean -fxd)
          rm -rf install *.log'''
  }

  // Checkout git repositories
  stage('Checkout') {
    // Checkout RISC-V Build Scripts then Upstream components
    dir('riscv-gnu-toolchain') {
      git url: 'https://github.com/riscv/riscv-gnu-toolchain.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-binutils') {
      git url: 'https://github.com/embecosm/riscv-binutils-gdb.git', branch: 'embecosm-cgen-assembler'
    }
    dir('riscv-gnu-toolchain/riscv-gcc') {
      checkout([$class: 'GitSCM',
                branches: [[name: '*/master']],
                extensions: [[$class: 'CloneOption',
                              timeout: 30]],
                userRemoteConfigs: [[url: 'https://github.com/gcc-mirror/gcc.git']]])
    }
    dir('riscv-gnu-toolchain/riscv-glibc') {
      git url: 'https://sourceware.org/git/glibc.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-dejagnu') {
      git url: 'https://github.com/riscv/riscv-dejagnu.git', branch: 'riscv-dejagnu-1.6'
    }
    dir('riscv-gnu-toolchain/riscv-newlib') {
      git url: 'https://sourceware.org/git/newlib-cygwin.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-qemu') {
      git url: 'git://git.qemu.org/qemu.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-gdb') {
      git url: 'https://sourceware.org/git/binutils-gdb.git', branch: 'master'
    }
  }

  // Build toolchain
  stage('Build Tool Chain') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('riscv-gnu-toolchain') {
            sh './configure --prefix=${WORKSPACE}/install --with-arch=rv32gc --with-abi=ilp32 > ../build.log 2>&1'
            sh 'make -j$(nproc) >> ../build.log 2>&1'
          }
        }
      }
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'build.log'
      }
    }
  }

  // Run Tests
  stage('GCC Regression') {
    timeout(120) {
      try {
        docker.image('embecosm/buildenv').inside {
          dir('riscv-gnu-toolchain') {
            sh '''PATH=${WORKSPACE}/install/bin:$PATH
                  make -j$(nproc) check-gcc-newlib > ../check-gcc.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-gcc.log, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/gcc/gcc.sum, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/gcc/gcc.log,  riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/g++/g++.sum, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/g++/g++.log'
      }
    }
  }
}
