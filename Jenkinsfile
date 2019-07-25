node ('dockerbuilder') {
  // Cleanup previous build and log files
  stage('Cleanup') {
    deleteDir()
  }

  // Checkout git repositories
  stage('Checkout') {
    checkout scm
    // Checkout RISC-V Build Scripts then Upstream components where possible
    dir('riscv-gnu-toolchain') {
      git url: 'https://github.com/riscv/riscv-gnu-toolchain.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-binutils') {
      git url: 'https://github.com/bminor/binutils-gdb.git', branch: 'master'
    }
    dir('riscv-gnu-toolchain/riscv-gcc') {
      checkout([$class: 'GitSCM',
                branches: [[name: '*/master']],
                extensions: [[$class: 'CloneOption',
                              timeout: 30]],
                userRemoteConfigs: [[url: 'https://github.com/gcc-mirror/gcc.git']]])
    }
    dir('riscv-gnu-toolchain/riscv-glibc') {
      git url: 'https://github.com/riscv/riscv-glibc.git', branch: 'riscv-glibc-2.26'
    }
    dir('riscv-gnu-toolchain/riscv-dejagnu') {
      git url: 'https://github.com/riscv/riscv-dejagnu.git', branch: 'riscv-dejagnu-1.6'
    }
    dir('riscv-gnu-toolchain/riscv-newlib') {
      git url: 'https://github.com/bminor/newlib.git', branch: 'master'
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
    timeout(240) {
      try {
        sh 'mkdir ${WORKSPACE}/docker/install'
        baseimage = docker.build('tmp-base', '-f docker/Stage1.dockerfile --no-cache docker')
        baseimage.inside('-v ${WORKSPACE}/docker/install:/usr/local') {
          dir('riscv-gnu-toolchain') {
            sh './configure --prefix=/usr/local --enable-multilib > ../build.log 2>&1'
            sh 'make -j$(nproc) newlib linux >> ../build.log 2>&1'
            sh 'cd /usr/local/bin && for i in riscv64-*; do ln -s $i "riscv32-${i#riscv64-}"; done'
          }
        }
      }
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'build.log'
      }
    }
  }

  // Run Tests
  stage('GCC Regression (Newlib)') {
    timeout(300) {
      try {
        baseimage.inside('-v ${WORKSPACE}/docker/install:/usr/local') {
          dir('riscv-gnu-toolchain') {
            sh '''USER=jenkins make -j$(nproc) report-newlib > ../check-newlib.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-newlib.log, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/*/*.sum, riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/testsuite/*/*.log'
      }
    }
  }

  // Run Tests
  stage('GCC Regression (Linux)') {
    timeout(300) {
      try {
        baseimage.inside('-v ${WORKSPACE}/docker/install:/usr/local') {
          dir('riscv-gnu-toolchain') {
            sh '''USER=jenkins make -j$(nproc) report-linux > ../check-linux.log 2>&1'''
          }
        }
      }
      catch (Exception e) {}
      finally {
        archiveArtifacts allowEmptyArchive: true, fingerprint: true, artifacts: 'check-linux.log, riscv-gnu-toolchain/build-gcc-linux-stage2/gcc/testsuite/*/*.sum, riscv-gnu-toolchain/build-gcc-linux-stage2/gcc/testsuite/*/*.log'
      }
    }
  }

  // Package final toolchain
  stage('Package') {
    finalimage = docker.build('embecosm/riscv-gnu-toolchain', '-f docker/Stage2.dockerfile --no-cache docker')
    finalimage.push("build${env.BUILD_NUMBER}")
    finalimage.push(new Date().format('yyyyMMdd-HHmmss'))
    finalimage.push('latest')
  }
}
